#encoding:UTF-8
#!/usr/bin/env ruby

require 'rubygems'
require 'FasterCSV'
require 'httparty'
require 'json'
require 'highline/import'

def get_input(prompt="Enter >",show = true)
     ask(prompt) {|q| q.echo = show}
end
filename = ARGV.shift or raise "Enter Filepath to CSV as ARG1"

class GitHub
  include HTTParty
  base_uri 'https://api.github.com'

end
user = get_input("Enter Username >")
password = get_input("Enter Password >", "*")
GitHub.basic_auth user, password


visited_labels = []
FasterCSV.open filename, :headers => true do |csv|
  csv.each do |r|
    body = {
      :title => r['Story'],
      :body => r['Description'],
    }
    labels = []

    if r['Labels'] != ''
      r['Labels'].split(',').each do |label|
        label = label.strip
        color ='' 
        3.times { 
          color << "%02x" % rand(255)
        }
       unless visited_labels.include? label
        labels << {:name => label, :color =>color} 
       end
      end
      labels.each do |label|
        p label
        label = GitHub.post '/repos/robotarmy/driveless/labels', :body => JSON.generate(label)
        p label
      end
    end
    
    body[:labels] = r['Labels'].split(',').map {|l|l.strip} if r['Labels'] != ''

   
    p json_body = JSON.generate(body)
    issue = GitHub.post '/repos/robotarmy/driveless/issues', :body => json_body
    p issue

    r.each do |f|
      if f[0] == 'Note'
        next unless f[1]
        body = { :body => f[1] }
        GitHub.post "/repos/robotarmy/driveless/issues/#{issue.parsed_response['number']}/comments", :body => JSON.generate(body)
      end
    end
  end
end
