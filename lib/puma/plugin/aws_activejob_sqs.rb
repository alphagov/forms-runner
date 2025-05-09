# TODO: contribute this back to the aws-sdk-rails gem
require "puma/plugin"

module Puma
  module Plugin
    module AwsActivejobSqs
      module PluginInstanceMethods
        class << self
          attr_writer :sqs_poller_options

          def sqs_poller_options
            @sqs_poller_options ||= {}
          end
        end

        attr_reader :puma_pid, :sqs_poller_pid, :log_writer

        def start(launcher)
          @log_writer = launcher.log_writer
          @puma_pid = $$

          in_background do
            monitor_sqs_poller
          end

          launcher.events.on_booted do
            # TODO: there should be separate process per queue
            @sqs_poller_pid = fork do
              Thread.new { monitor_puma }
              Aws::ActiveJob::SQS::Poller.new(self.class.sqs_poller_options.to_h.compact).run
            end
          end

          launcher.events.on_stopped { stop_sqs_poller }
          launcher.events.on_restart { stop_sqs_poller }
        end

      private

        def stop_sqs_poller
          return unless sqs_poller_pid

          begin
            Process.waitpid(sqs_poller_pid, Process::WNOHANG)
            log "Stopping SQS Poller..."
            Process.kill(:INT, sqs_poller_pid)
            Process.wait(sqs_poller_pid)
          rescue Errno::ECHILD, Errno::ESRCH
            log "SQS Poller process not found or already stopped."
          end
        end

        def monitor_puma
          monitor(:puma_dead?, "Detected Puma has gone away, stopping SQS Poller...")
        end

        def monitor_sqs_poller
          monitor(:sqs_poller_dead?, "Detected SQS Poller has gone away, stopping Puma...")
        end

        def monitor(process_dead, message)
          loop do
            if send(process_dead)
              log message
              Process.kill(:INT, $$)
              break
            end
            sleep 2
          end
        end

        def sqs_poller_dead?
          if sqs_poller_started?
            Process.waitpid(sqs_poller_pid, Process::WNOHANG)
          end
          false
        rescue Errno::ECHILD, Errno::ESRCH
          true
        end

        def sqs_poller_started?
          sqs_poller_pid.present?
        end

        def puma_dead?
          Process.ppid != puma_pid
        end

        def log(...)
          log_writer.log(...)
        end
      end
    end
  end
end

Puma::Plugin.create do
  include Puma::Plugin::AwsActivejobSqs::PluginInstanceMethods
end
