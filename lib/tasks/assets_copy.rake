task :assets_copy do
  system('yarn run build:files')
end

# Copy image and font files from node_modules for use in production
Rake::Task['assets:precompile'].enhance ['assets_copy']
