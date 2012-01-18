require 'date'
require 'health_graph' # forked version of health_graph gem, https://github.com/andrewpbrett/health_graph

token = "your_token"
user = HealthGraph::User.new(token)

# expects a .csv file with headers:
# "Title","Start","End","Duration","Description"

contents = File.open("/Users/andy/Desktop/export.csv", "rb").read

contents.split("\n").each do |line|

  # filter out 24 hour events
  next if line.include?("24:0:0") || line.include?("Description")

  array = line.split("\",\"")  
  
  # change offset. only relevant if you moved from nyc to california over the course of the import
  start_time = DateTime.parse(array[1] + "-05:00").new_offset("-08:00").strftime("%a, %d %b %Y %H:%M:%S")

  title = array[0]
  type = ""
  if title.match(/Lift/i)
    type = "Other"
  elsif title.match(/Bike/i)
    type = "Cycling"
  elsif title.match(/Swim/i)
    type = "Swimming"
  elsif title.match(/Erg/i)
    type = "Rowing"
  else
    type = "Running"
  end
  
  
  if title.match(/[\d\.]+\smi/)
    total_distance = title.match(/([\d\.]+\s)mi/)[1].to_f*1609
  elsif title.match(/\s[\d,]{3,5}\syards/)
    total_distance = title.match(/\s([\d,]{3,5})\syards/)[1].to_f*0.9144
  elsif title.match(/\s[\d]{1,2}k/)
    total_distance = title.match(/\s([\d]{1,2})k/)[1].to_f*1000.0
  end
  
  if title.match(/[\d]{0,1}\:[\d]{1,2}\:[\d]{2}/)
    hours   = title.match(/([\d]{0,2})[\:]?([\d]{1,2})\:([\d]{2})/)[1]
    minutes = title.match(/([\d]{0,2})[\:]?([\d]{1,2})\:([\d]{2})/)[2]
    seconds = title.match(/([\d]{0,2})[\:]?([\d]{1,2})\:([\d]{2})/)[3]
    duration = seconds.to_f + minutes.to_f*60 + hours.to_f*3600
  elsif title.match(/[\d]{0,2}\:[\d]{2}/)
    minutes = title.match(/([\d]{0,2})\:([\d]{2})/)[1]
    seconds = title.match(/([\d]{0,2})\:([\d]{2})/)[2]
    duration = seconds.to_f + minutes.to_f*60 + hours.to_f*3600
    duration = seconds.to_f*60 + minutes.to_f*3600 if minutes == "1"
  elsif type == "Running" and total_distance
    duration = total_distance*0.298258172
  elsif type == "Swimming" and total_distance
    duration = total_distance*1.5
  end
  
  total_distance = 0 if total_distance.nil?
  
  notes = title.gsub(/^\"/, "")
  
  params = { start_time: start_time, total_distance: total_distance, 
    duration: duration, notes: notes, type: type }

  user.new_fitness_activity(params) if !duration.nil? and type != "Other"
end