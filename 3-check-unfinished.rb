require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|

  opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
  opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
  opts.on('-m', '--masterproject NAME', 'Master Project') { |v| options[:master] = v }
  opts.on('-d', '--releasedate DATE', 'Release Date') { |v| options[:date] = v }
  opts.on('-f', '--file FILE', 'Projects file') { |v| options[:file] = v }
  
end.parse!

#username = ''
#password = ''
username = options[:username]
password = options[:password]

ignore_tags = ['qa','poc']
last_release_date = Date.parse(options[:date],'%e %b %Y')
master = options[:master]
# testing master project ID = y672cuxov5x6swn64tlaz5jwcrez0wid

puts 'Connecting to GoodData...'
puts 'Listing objects updated after ' + last_release_date.to_s + '.'

GoodData.with_connection(username, password) do |client|
    
    #GoodData.logging_on
    #GoodData.logger.level = Logger::DEBUG
    
    GoodData.with_project(master) do |project|

     dashboards_to_migrate = project.dashboards.select { |dashboard| dashboard.updated > last_release_date && !(ignore_tags.any? { |tag| dashboard.tags.include?(tag)})}

     puts 'Check unfinished dashboards...'

      dashboards_to_migrate.each do |dashboard|
   	    if !(dashboard.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
        if (dashboard.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
        if (dashboard.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
        if (unlocked != '' || missing_desc != '' || unlisted != '')
            then
        puts 'https://secure.gooddata.com' + dashboard.uri + ' | ' + dashboard.title + unlocked + missing_desc + unlisted
            end
	  end
      
      reports_to_migrate = project.reports.select { |report| report.updated > last_release_date && !(ignore_tags.any? { |tag| report.tags.include?(tag)}) }
      
      puts 'Check unfinished reports...'
      
      reports_to_migrate.each do |report|
          if !(report.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
          if (report.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
          if (report.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
          if (unlocked != '' || missing_desc != '' || unlisted != '')
              then
          puts 'https://secure.gooddata.com' + report.uri + ' | ' + report.title + unlocked + missing_desc + unlisted
              end
          end
    
    
      metrics_to_migrate = project.metrics.select { |metric| metric.updated > last_release_date && !(ignore_tags.any? { |tag| metric.tags.include?(tag)})  }

	  puts 'Check unfinished metrics...'

      metrics_to_migrate.each do |metric|
   	    if !(metric.locked?) then unlocked = ' | UNLOCKED!'  else unlocked = '' end
        if (metric.summary == '') then missing_desc = ' | MISSING DESCRIPTION' else missing_desc = '' end
        if (metric.meta['unlisted'] == 1) then unlisted = ' | UNLISTED!' else unlisted = '' end
        if (unlocked != '' || missing_desc != '' || unlisted != '')
            then
        puts 'https://secure.gooddata.com' + metric.uri + ' | ' + metric.title + unlocked + missing_desc + unlisted
            end
    end

    end
end

puts 'Disconnecting ...'
GoodData.disconnect