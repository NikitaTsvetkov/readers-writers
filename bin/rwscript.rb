require 'thread'
require 'jruby/profiler'
class Timer
  def initialize
    puts "timer ready"
    @should_tick = true
  end
  def every x , &block
    #while @should_tick 
    80.times do
      puts "try tick"
      sleep(x)
      yield block
    end
  end
end

class Buffer
  attr_reader :amount , :semaphore, :capacity 
  def initialize 
    @semaphore = Mutex.new
    @amount = 0
    @capacity = 100
  end
  
  def put
    raise "buffer overflow, please wait!" if (@amount + 1 > @capacity)
    @amount += 1
    1
  end
  
  def get
    raise "nothing to consume, please wait!" if (@amount - 1 < 0)
    @amount -= 1
    1
  end
end

class Consumer
  attr_reader :needed_amount
  def initialize (consumer_num, buffer, delay)
    @consumer_num = consumer_num 
    @buffer = buffer
    @needed_amount = 0
    @delay = delay
    @timer = Timer.new
  end
  
  def start_consume
    @timer.every(@delay){ self.consume }
  end
  
  def consume 
    puts "#{@consumer_num} consuming"
     @buffer.semaphore.synchronize do
       begin
         @needed_amount += 1
         @needed_amount -= @buffer.get while @needed_amount > 0 
       rescue Exception => e
         puts e.message + " in consumer \# #{@consumer_num} , it needs #{@needed_amount} more items"
       end
     end
  end
end

class Producer
  attr_reader :produced_amount
  def initialize (producer_num, buffer, delay)
    puts "producer ready"
    @buffer = buffer
    @produced_amount = 0
    @producer_num = producer_num
    @delay = delay
    @timer = Timer.new
  end
  
  def start_produce
    @timer.every(@delay){ self.produce }
  end
  
  def produce
    puts "#{@producer_num} producing"     
    @buffer.semaphore.synchronize do
       begin
         @produced_amount += 1
         @produced_amount -= @buffer.put while @produced_amount > 0 
       rescue Exception => e
         puts e.message + " in producer \# #{@producer_num} , it produced #{@producer_num} more items"
         
       end
     end
  end
end

semaphore = Mutex.new
profile_data = JRuby::Profiler.profile do
buffer = Buffer.new
consumers_threads = Array.new
0.upto(10) do |x|
  consumers_threads << Thread.new do
    puts "in thread"
    consumer = Consumer.new(x,buffer, 3)
    consumer.start_consume
  end
end

producers_threads = Array.new
0.upto(12) do |x|
  producers_threads << Thread.new do
    producer = Producer.new(x, buffer, 3)
    producer.start_produce
  end
end

sleep(30)
end

