require 'date'
require 'gooddata'
require 'csv'
require 'optparse'
require 'yaml'

# get all parameters
options = {}
OptionParser.new do |opts|
    
    opts.on('-u', '--username USER', 'Username') { |v| options[:username] = v }
    opts.on('-p', '--password PASS', 'Password') { |v| options[:password] = v }
    opts.on('-s', '--startproject NAME', 'Start Project') { |v| options[:start] = v }
    opts.on('-d', '--develproject NAME', 'Development Project') { |v| options[:devel] = v }
    opts.on('-h', '--hostname NAME', 'Hostname') { |v| options[:server] = v }

end.parse!

# get parameters from the user input
username = options[:username]
password = options[:password]
start = options[:start]
devel = options[:devel]
server = options[:server]

# if whitelabel is not specified set to default domain
if server.to_s.empty? then server = 'https://secure.gooddata.com' end

puts 'Connecting to GoodData...'
puts 'Checking for missing reports and metrics.'

# connect to gooddata and check missing reports and metrics between projects
GoodData.with_connection(login: username, password: password, server: server) do |client|
    
    start_reports = []
    devel_reports = []
    start_metrics = []
    devel_metrics = []
    
    # get all reports and metrics from devel project
    GoodData.with_project(devel) do |project|
        
        project.reports.each do |report|
                devel_reports.push(report.uri.gsub(devel,"pid"))
        end
        
        project.metrics.each do |metric|
                devel_metrics.push(metric.uri.gsub(devel,"pid"))
        end
        
    end
    
    # get all reports and metrics from start project
    GoodData.with_project(start) do |project|
        
        project.reports.each do |report|
            start_reports.push(report.uri.gsub(start,"pid"))
        end
        
        project.metrics.each do |metric|
            start_metrics.push(metric.uri.gsub(start,"pid"))
        end
        
    end
    
    # print the diff for metrics
    puts 'Metrics missing in Devel Project:'
    metrics_diff = start_metrics - devel_metrics
    
    
    # prepare output array for complete links reports
    met = []
    
    metrics_diff.each do |m|
        
        met.push(server + "/#s=/gdc/projects/" + start + '|objectPage|' + m.gsub!("pid",start))
        
    end
    
    if metrics_diff.empty? then puts 'NOTHING IS MISSING' else puts metrics_diff end
    
    puts 'Reports missing in Devel Project:'
    
    # print the diff for reports
    reports_diff = start_reports - devel_reports
    
    # prepare output array for complete links reports
    rep = []
    reports_diff.each do |r|
        rep.push(server + "/#s=/gdc/projects/" + start + "%7CanalysisPage%7Chead%7C" + r.gsub!("pid",start))
    end
    
    if reports_diff.empty? then puts 'NOTHING IS MISSING' else puts rep end
    
end

puts 'Disconnecting...'
GoodData.disconnect
