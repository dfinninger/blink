#
# BlinkUtils - utilities that are used throughout the game
#
#   Author:     Devon Finninger
#   Init Date:  2014-06-05
#

module BlinkUtils
  def log(caller_class = nil, message)
    if caller_class
      str = caller_class.class.name.split('::').last
    else
      str = "[undefined]"
    end
    print "#{str}::#{Time.now.strftime("%T.%L")} => "
    puts message
  end
end
