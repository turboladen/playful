require 'eventmachine'

EM.run do
  op = proc do
    2 + 2
  end

  callback = proc do |count|
    puts "2 + 2 == #{count}"
    #EM.stop
  end

  EM.defer(op, callback)
end
