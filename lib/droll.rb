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

==== Threshold Acceptance

Using k instead of d, x, or e in the die code indicates that out of the number
of dice rolled, only the highest of them will be kept ("k" is for "keep").
Thus, for this die code, only the highest result is kept:

        2k20

If the k is capitalized, the lowest result is kept instead of the highest.

==== Threshold Counting

In some cases, it may be desirable to count the number of dice that produce a
result of the maximum value the die can produce.  Use n instead of d, x, e, or
k in this die code:

        3n4

This will yield a result that is a count of four-sided dice that meet a
threshold equal to the maximum value of the die (4).  The "n" is short for
"number", as in "the number of dice that meet or exceed the threshold".

==== Alternate Thresholds

A threshold number may be specified by a period/fullstop character followed by
a number, with any modifiers coming after it:

        3x4.3+7

In this case, the die code is treated the same way as in the previous 3x4+7
example, except that it explodes on 3 or 4, and not just on 4.

For threshold acceptance, the threshold number is used to determine how many
of the highest or lowest die values will be kept.  In this die code, then, the
result is the sum of the highest three die values:

        4k6.3
  
In the case of threshold counting, it would yield a result that is a count of
four-sided dice that meet or exceed a threshold of 3, which means a count of
all dice with values of 3 or 4, before adding the number 7 to the total with
this die code:

        3n4.3+7

Note that for threshold counting, the modifier is applied to the count, and not
to die roll values.

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
  attr_reader :dcode, :dice, :dmax, :dval, :modifier, :pcode, :roll_type, :sign, :threshold

=begin rdoc

This method returns the version number for the Droll gem.

=end

  def self.version; '1.0.3'; end

=begin rdoc

The +die_code+ argument is any valid die code recognized by Droll.

        Droll.new '4x7+3'

=end

  def initialize die_code
    @dcode = die_code.strip
    @allowed = Regexp.new(
      /^[1-9]{,2}[A-Za-z]\d?[1-9]{1,2}(\.\d+)?([+-]\d+)?(\s*.+)?$/
    )

    process_die
  end

  private

  def valid?
    validation = dcode.match @allowed

    if dcode.size < 2
      validation = false
    elsif 1 > dmax
      validation = false
    elsif 1 > threshold
      validation = false
    elsif 1 > dice
      validation = false
    elsif 0 == dval[0].to_i
      if 1 > dmax
        validation = false
      end
    elsif 0 != dval[0].to_i
      if 2 > dmax
        validation = false
      elsif roll_type.match(/[^Kk]/) and 2 > threshold
        validation = false
      end
    end

    return validation
  end

  def process_die
    die_roll, @sign, mod = dcode.split(/([+-])/)
    num, @roll_type, die_vals = die_roll.split(/([A-Za-z])/)
    @dval, thresh = die_vals.to_s.split(/\./)
    @dval = dval.to_s
    @dmax = dval.to_i

    if thresh
      @threshold = thresh.to_i
    else
      @threshold = roll_type.match(/[KkN]/) ? 1 : dmax
    end

    @dice = (num == '' ? 1 : num.to_i)
    sign ||= '+'
    @modifier = mod.to_i
  end

  def get_discrete(dval)
    dval.match(/^0/) ? rand(dmax + 1) : 1 + (rand dmax)
  end

  def roll_die(die_value, die_type, die_threshold)
    discrete_rolls = [get_discrete(die_value)]

    if die_type == 'x'
      0.upto(999) do
        if discrete_rolls.last < die_threshold
          break
        else
          discrete_rolls.push get_discrete die_value
        end
      end
    end

    discrete_rolls.compact
  end

  def analyze_rolls method, results
    case method
    when 'k'
      sum_thresh_high_dice results
    when 'K'
      sum_thresh_low_dice results
    when 'n'
      count_dice_min_thresh results
    when 'N'
      count_dice_max_thresh results
    end
  end

  public

=begin rdoc

This method takes an array of numeric values as its sole argument, and compares
it to the instantiated die code's threshold value.  It returns an integer value
equal to the number of values in the array argument that are equal to or
greater than the threshold value.

Given a threshold of 2:

        count_dice_min_thresh([0,1,2,3])        #=> 2

        count_dice_min_thresh([0,1])            #=> 0

=end

  def count_dice_min_thresh dresults
    dresults.reject {|n| n < threshold }.size
  end

=begin rdoc

This method takes an array of numeric values as its sole argument, and compares
it to the instantiated die code's threshold value.  It returns an integer value
equal to the number of values in the array argument that are equal to or
greater than the threshold value.

Given a threshold of 1:

        count_dice_max_thresh([0,1,2,3])        #=> 2

        count_dice_max_thresh([2,3])            #=> 0

=end

  def count_dice_max_thresh dresults
    dresults.reject {|n| n > threshold }.size
  end

=begin rdoc

This method takes an array of numeric values as its sole argument, and returns
the total of the highest N values in the array, where N is the instantiated die
code's threshold value.

Given a die code of 3k02:

        sum_thresh_high_dice([2, 2, 2])         #=> 2

        sum_thresh_high_dice([0, 0, 1])         #=> 1

Given a die code of 3k02.2:

        sum_thresh_high_dice([0, 1, 2])         #=> 3

        sum_thresh_high_dice([0, 0, 1])         #=> 1

=end

  def sum_thresh_high_dice dresults
    dresults.sort.reverse[0..(threshold - 1)].inject(:+)
  end

=begin rdoc

This method takes an array of numeric values as its sole argument, and returns
the total of the lowest N values in the array, where N is the instantiated die
code's threshold value.

Given a die code of 3K02:

        sum_thresh_low_dice([1, 1, 1])          #=> 1

        sum_thresh_low_dice([0, 1, 2])          #=> 0

Given a die code of 3K02.2:

        sum_thresh_low_dice([0, 1, 2])          #=> 1

        sum_thresh_low_dice([1, 2, 2])          #=> 3

=end

  def sum_thresh_low_dice dresults
    dresults.sort[0..(threshold - 1)].inject(:+)
  end

=begin rdoc

This method takes an array of numeric values as its sole argument, and compares
the total of the values in the array to the product of the instantiated die
code's threshold value and number of dice value.  Unless that product is
greater than that total, the results of a die roll of 1xX.Y are appended to the
array provided in the method argument, where X is the value of the instantiated
die code and Y is the threshold of the instantiated die code.

Given a die code of 2e2:

    explode_on_max_total([2, 2])                #=> [2, 2, ...]

    explode_on_max_total([2, 1])                #=> [2, 1]

=end

  def explode_on_max_total dresults
    roll_total = dresults.flatten.map {|result| result.to_i }.inject(:+)

    unless roll_total < (threshold * dice)
      dresults.push(roll_die dval, 'x', threshold)
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

  def roll formatted=true
    results = Array.new

    return "bad die code: #{dcode}" unless valid?

    dice.times do
      results.push(
        roll_die dval, roll_type, threshold
      ).flatten!
    end

    if roll_type == 'e'
      results = explode_on_max_total results
    end

    total = if %w(k K n N).include? roll_type
      analyze_rolls roll_type, results
    else # "normal" totaling
      results.map {|s| s.to_i }.inject(:+)
    end

    if sign == '+'
      total += modifier
    elsif sign == '-'
      total -= modifier
    end

    if formatted
      "#{dcode}: #{results} #{sign} #{modifier} = #{total}"
    else
      total
    end
  end
end
