require 'thread'

require 'timers'

class Buffer
  attr_reader :amount , :semaphore, :capacity 
  def initialize (mutex)
    @semaphore = mutex
    @amount = 0
    @capacity = 100
  end
  
  def put
    raise "buffer overflow, please wait!" if (@amount + 1 > @capacity)
    @amount += 1
  end
  
  def get
    raise "nothing to consume, please wait!" if (@amount - 1 < 0)
    @amount -= 1
  end
end

class Consumer
  attr_reader :needed_amount
  def initialize (consumer_num, buffer, delay)
    @consumer_num = consumer_num 
    @buffer = buffer
    @needed_amount = 0
    @delay = delay
    @timer = new Timer
  end
  def consume 
     semaphore.synchronize do
       begin
         @buffer.get if @needed_amount > 0 
       rescue Exception => e
         puts e.message + " in consumer \# #{@consumer_num} , it needs #{@needed_amount} more items"
       end
     end
  end
end

class Producer
  attr_reader :produced_amount
  def initialize (producer_num, buffer, delay)
    @buffer = buffer
    @produced_amount = 0
    @producer_num = producer_num
    @delay = delay
  end
  def produce
     semaphore.synchronize do
       begin
         @buffer.put
       rescue Exception => e
         puts e.message + " in consumer \# #{@consumer_num}"
       end
     end
  end
end

semaphore = Mutex.new

a = Thread.new {
  semaphore.synchronize {
    # access shared resource
  }
}

b = Thread.new {
  semaphore.synchronize {
    # access shared resource
  }
}