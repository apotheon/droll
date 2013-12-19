=begin rdoc

Droll provides a Ruby class that parses die codes as normally presented in
roleplaying game texts, i.e.:

        3d4+7

This die code indicates that four-sided dice numbered 1-4 should be rolled --
three of them.  Their totals should be added together, and the number 7 should
be added to the total.  If only one die should be rolled, it can be represented
as either 1d4 or, in abbreviated form, as d4.  Numbers may be either added or
subtracted (e.g. 3d4-7), or no modifiers may be applied at all (e.g. 3d4).  A
"normal" six-sided die, a cube with numbers or "pips" to indicate the value of
each face, is represented by 1d6 or d6.  Droll's handling of die codes is case
sensitive, such that 3D4 will not work as described above.

=== Additional Syntax Options

The syntax accepted by Droll is more sophisticated than the above might
indicate, to accommodate special die roll semantics.

==== Exploding

Dice in some game systems may "explode".  This means that, under certain
conditions, the result on a die may indicate that another die should be rolled
and added to the total as well.  The most common case is where any die that
produces the maximum possible value for that die indicates that another die
should be rolled and added to the total.  Normal exploding die syntax uses x
instead of d in the die code:

        3x4+7

In this case, when each d4 is rolled, an additional die is rolled if that die's
value is 4 (the maximum value for the die).  The modifier is applied to the
total after all dice (including exploding dice) are rolled and added together.

An alternate exploding method only explodes if *all* dice rolled produce a
result of the maximum value each die can produce.  This uses e instead of d or
x in the die code:

        3e4+7

In this case, if the total of the 3d4 roll is 12, an additional d4 is rolled
and added to the running total, and if that (or any subsequent d4 rolls that
are part of the same 3e4+7 dice roll resolution) is another 4 result, it
explodes again.  If two 4 results and a 3 result come from that roll of 3d4, no
exploding occurs, leaving an 11 result from the virtual dice.  As normal, when
all die rolling is resolved and summed, the modifier (+7 in this case) is
applied to the total.

==== Threshhold Acceptance

Using k instead of d, x, or e in the die code indicates that out of the number
of dice rolled, only the highest of them will be kept ("k" is for "keep").
Thus, for this die code, only the highest result is kept:

        2k20

If the k is capitalized, the lowest result is kept instead of the highest.

==== Threshhold Counting

In some cases, it may be desirable to count the number of dice that produce a
result of the maximum value the die can produce.  Use n instead of d, x, e, or
k in this die code:

        3n4

This will yield a result that is a count of four-sided dice that meet a
threshhold equal to the maximum value of the die (4).  The "n" is short for
"number", as in "the number of dice that meet or exceed the threshhold".

==== Alternate Threshholds

A threshhold number may be specified by a period/fullstop character followed by
a number, with any modifiers coming after it:

        3x4.3+7

In this case, the die code is treated the same way as in the previous 3x4+7
example, except that it explodes on 3 or 4, and not just on 4.

For threshhold acceptance, the threshhold number is used to determine how many
of the highest or lowest die values will be kept.  In this die code, then, the
result is the sum of the highest three die values:

        4k6.3
  
In the case of threshhold counting, it would yield a result that is a count of
four-sided dice that meet or exceed a threshhold of 3, which means a count of
all dice with values of 3 or 4, before adding the number 7 to the total with
this die code:

        3n4.3+7

Note that for threshhold counting, the modifier is applied to the count, and
not to die roll values.

==== Alternate Minimum Value

Dice whose value ranges start at 0 instead of 1 are also possible.  To indicate
a 0-N range, precede the die value with a 0 in the die code:

        3d03

This die code rolls three virtual dice whose values may be anywhere in the
range of 0-3 and returns the total for all three dice.

=== Usage:

==== API:

        require 'droll'
        
        droll = Droll.new '3x4.3+7'
        puts droll.roll

The above example produces output like the following:

        3x4.3+7: [4, 1, 4, 4, 2, 2] + 7 = 24

==== Command Line:

        droll 3x4.3+7

The above example produces output like the API usage example.

=end


class Droll

=begin rdoc

This method returns the version number for the Droll gem.

=end

  def self.version; '1.0.1'; end

=begin rdoc

The +dcode+ argument is any valid die code recognized by Droll.

        Droll.new '4x7+3'

=end

  def initialize(dcode)
    @dcode = dcode
    @pcode = process_die
  end

  private

  def valid?
    if @dcode.match(
      /^[1-9]*[0-9]*[A-Za-z][0-9]?[1-9]+[0-9]?(\.\d+)?[+-]?[0-9]*\s*(.*)$/
    )
      validation = true
    else
      validation = false
    end

    if 1 > @pcode['val'].to_i
      return false
    end
    
    if 1 > @pcode['thresh'].to_i
      return false
    end

    if 1 > @pcode['num'].to_i
      return false
    end

    if 0 == @pcode['val'][0].to_i
      if 1 > @pcode['val'].to_i
        return false
      end
    end

    if 0 != @pcode['val'][0].to_i
      if 2 > @pcode['val'].to_i
        return false
      elsif @pcode['type'].match(/[^Kk]/) and 2 > @pcode['thresh'].to_i
        return false
      end
    end

    return validation
  end

  def process_die
    d = Hash.new
    die_roll, d['sign'], d['mod'] = @dcode.split(/([+-])/)
    d['num'], d['type'], die_vals = die_roll.split(/([A-Za-z])/)
    d['val'], d['thresh'] = die_vals.split(/\./)
    d['val'] = d['val'].to_s

    if d['type'].match(/[KkN]/)
      d['thresh'] ||= 1
    else
      d['thresh'] ||= d['val'].sub(/^0/, '')
    end

    d['num'] = 1 if d['num'] == ''
    d['sign'] ||= '+'
    d['mod'] ||= 0

    return d
  end

  def get_discrete(dval)
    dval.match(/^0/) ? rand(dval.to_i + 1) : 1 + (rand dval.to_i)
  end

  def roll_die(die_value, die_type, die_threshhold)
    discrete_rolls = [get_discrete(die_value)]

    case die_type
    when 'x'
      c = 0
      while c < 1000
        if discrete_rolls[-1] >= die_threshhold.to_i
          discrete_rolls.push get_discrete(die_value)
          c += 1
        else
          break
        end
      end
    end

    discrete_rolls.compact
  end

  public

=begin rdoc

This method takes an array of numeric values as its sole argument, and compares
it to the instantiated die code's threshhold value.  It returns an integer
value equal to the number of values in the array argument that are equal to or
greater than the threshhold value.

Given a threshhold of 2:

        count_dice_min_thresh([0,1,2,3])        #=> 2

        count_dice_min_thresh([0,1])            #=> 0

=end

  def count_dice_min_thresh(dresults)
    num_dice_min_thresh = dresults.reject do |n|
      n < @pcode['thresh'].to_i
    end.size
  end

=begin rdoc

This method takes an array of numeric values as its sole argument, and compares it to the instantiated die code's threshhold value.  It returns an integer value equal to the number of values in the array argument that are equal to or greater than the threshhold value.

Given a thresshold of 1:

        count_dice_max_thresh([0,1,2,3])        #=> 2

        count_dice_max_thresh([2,3])            #=> 0

=end

  def count_dice_max_thresh(dresults)
    num_dice_max_thresh = dresults.reject do |n|
      n > @pcode['thresh'].to_i
    end.size
  end

=begin rdoc

This method takes an array of numeric values as its sole argument, and returns
the total of the highest N values in the array, where N is the instantiated die
code's threshhold value.

Given a die code of 3k02:

        sum_thresh_high_dice([2, 2, 2])         #=> 2

        sum_thresh_high_dice([0, 0, 1])         #=> 1

Given a die code of 3k02.2:

        sum_thresh_high_dice([0, 1, 2])         #=> 3

        sum_thresh_high_dice([0, 0, 1])         #=> 1

=end

  def sum_thresh_high_dice(dresults)
    dresults.sort.reverse[0..(@pcode['thresh'].to_i - 1)].inject(:+)
  end

=begin rdoc

This method takes an array of numeric values as its sole argument, and returns
the total of the lowest N values in the array, where N is the instantiated die
code's threshhold value.

Given a die code of 3K02:

        sum_thresh_low_dice([1, 1, 1])          #=> 1

        sum_thresh_low_dice([0, 1, 2])          #=> 0

Given a die code of 3K02.2:

        sum_thresh_low_dice([0, 1, 2])          #=> 1

        sum_thresh_low_dice([1, 2, 2])          #=> 3

=end

  def sum_thresh_low_dice(dresults)
    dresults.sort[0..(@pcode['thresh'].to_i - 1)].inject(:+)
  end

=begin rdoc

This method takes an array of numeric values as its sole argument, and compares the total of the values in the array to the product of the instantiated die code's threshhold value and number of dice value.  Unless that product is greater than that total, the results of a die roll of 1xX.Y are appended to the array provided in the method argument, where X is the value of the instantiated die code and Y is the threshhold of the instantiated die code.

Given a die code of 2e2:

    explode_on_max_total([2, 2])                #=> [2, 2, ...]

    explode_on_max_total([2, 1])                #=> [2, 1]

=end

  def explode_on_max_total(dresults)
    dice_total = dresults.map {|s| s.to_i }.inject(:+)
    unless (@pcode['thresh'].to_i * @pcode['num'].to_i) > dice_total
      dresults.push(
        roll_die @pcode['val'], 'x', @pcode['thresh']
      )
    end
    dresults.flatten
  end

=begin rdoc

By default, this method returns a string showing the die code rolled, the
individual die rolls that make up the complete roll of dice, the modifier
applied to the roll (showing "\+ 0" if no modifier was given), and the result,
in the following format:

        3d6+2: [3, 4, 1] + 2 = 10

If the +formatted+ argument is given a +false+ value, this method returns only
an integer equal to the total result.

=end

  def roll(formatted=true)
    running_totals = Array.new

    return "bad die code: #{@dcode}" unless valid?

    @pcode['num'].to_i.times do
      running_totals.push(
        roll_die @pcode['val'], @pcode['type'], @pcode['thresh']
      )
      running_totals.flatten!
    end

    if @pcode['type'] == 'e'
      running_totals = explode_on_max_total(running_totals)
    end

    if @pcode['type'] == 'k'
        total_result = sum_thresh_high_dice running_totals
    elsif @pcode['type'] == 'K'
        total_result = sum_thresh_low_dice running_totals
    elsif @pcode['type'] == 'n'
      total_result = count_dice_min_thresh running_totals
    elsif @pcode['type'] == 'N'
      total_result = count_dice_max_thresh running_totals
    else # "normal" totaling
      total_result = running_totals.map {|s| s.to_i }.inject do |sum,n|
        sum ? sum+n : n
      end
    end

    case @pcode['sign']
    when '+'
      total_result += @pcode['mod'].to_i
    when '-'
      total_result -= @pcode['mod'].to_i
    end

    if formatted
      result = "#{@dcode}: #{running_totals.inspect} "
      result += "#{@pcode['sign']} #{@pcode['mod']} = "

      result + total_result.to_s
    else
      total_result
    end
  end
end
