require 'minitest/autorun'
require 'minitest/rg'
require '../lib/droll'

class DrollTests < MiniTest::Test
  def test_process_die_correct
    # die codes that start with one for the number of dice or have no leading
    # numeral before the die type is specified should result in a one for
    # hash['num']; those starting with other numbers should have those numbers
    # instead

    literal = [[1, 'd', '08', '+', 3], [2, 'd', '10', '-', 4]]
    derived = [8, 10]
    elements = [:dice, :roll_type, :dval, :sign, :modifier]

    [0,1].each do |i|
      droll = Droll.new literal[i].join

      literal[i].each_with_index do |element, index|
        assert_equal droll.send(elements[index]), element
      end

      assert_equal droll.threshold, derived[i]
      assert_equal droll.dmax, derived[i]
    end
  end

  def test_get_discrete
    droll = Droll.new 'd2'

    # randomness is difficult to test effectively, dammit

    20.times do
      one_to_five = droll.send :get_discrete, '2'
      assert (0 < one_to_five) and (one_to_five < 3)

      zero_to_five = droll.send :get_discrete, '02'
      assert (-1 < zero_to_five) and (zero_to_five < 3)
    end
  end

  def test_valid?
    valid = %w(1d6 d6 d05)
    valid.each {|dcode| assert Droll.new(dcode).send :valid? }

    invalid = %w(0d6 d0 1d d)
    invalid.each {|dcode| refute Droll.new(dcode).send :valid? }
  end

  def test_roll_die
    droll = Droll.new '1d3'

    30.times do
      roll_die_result = droll.send(:roll_die, '6', 'd', '3')
      assert (0 < roll_die_result[0]) and (4 > roll_die_result[0])
    end
  end

  def test_explode_on_max_total
    droll = Droll.new '2e02'

    test_results = [0, 1, 2]
    assert_equal test_results, droll.explode_on_max_total(test_results)
    assert_equal droll.explode_on_max_total(test_results).size, 3

    test_results = [2, 2, 2]
    refute_equal test_results, droll.explode_on_max_total(test_results)
    assert droll.explode_on_max_total(test_results).size > 3
  end

  def test_sum_thresh_high_dice
    droll = Droll.new('3k02')
    results = [0, 1, 2]
    assert_equal 2, droll.sum_thresh_high_dice(results)

    droll = Droll.new('3k02.2')
    assert_equal 3, droll.sum_thresh_high_dice(results)
  end

  def test_sum_thresh_low_dice
    droll = Droll.new('3K02')
    results = [0, 1, 2]
    assert_equal 0, droll.sum_thresh_low_dice(results)

    droll = Droll.new('3K02.2')
    assert_equal 1, droll.sum_thresh_low_dice(results)
  end

  def test_count_dice_min_thresh
    droll = Droll.new '10n10'
    results = (1..10).to_a
    assert_equal 1, droll.send(:count_dice_min_thresh, results)
    
    droll = Droll.new '10n10.10'
    assert_equal 1, droll.send(:count_dice_min_thresh, results)
    
    droll = Droll.new '6n10.6'
    results = [4, 1, 7, 2, 6, 5]
    assert_equal 2, droll.send(:count_dice_min_thresh, results)
    
    droll = Droll.new '6n10.4'
    results = [3, 6, 8, 6, 8, 7]
    assert_equal 5, droll.send(:count_dice_min_thresh, results)
    
    results = [6, 9, 7, 8, 7, 7]
    assert_equal 6, droll.send(:count_dice_min_thresh, results)
    
    droll = Droll.new '3n10.7'
    results = [8, 1, 3]
    assert_equal 1, droll.send(:count_dice_min_thresh, results)
    
    results = [6, 2, 3]
    assert_equal 0, droll.send(:count_dice_min_thresh, results)
  end

  def test_count_dice_max_thresh
    droll = Droll.new '10N10'
    results = (1..10).to_a
    assert_equal 1, droll.send(:count_dice_max_thresh, results)
    
    droll = Droll.new '10N10.1'
    assert_equal 1, droll.send(:count_dice_max_thresh, results)
    
    droll = Droll.new '6N10.5'
    results = [4, 1, 7, 2, 6, 5]
    assert_equal 4, droll.send(:count_dice_max_thresh, results)
    
    droll = Droll.new '6N10.7'
    results = [3, 6, 8, 6, 8, 7]
    assert_equal 4, droll.send(:count_dice_max_thresh, results)
    
    results = [6, 9, 7, 8, 7, 7]
    assert_equal 4, droll.send(:count_dice_max_thresh, results)
    
    droll = Droll.new '3N10.2'
    results = [8, 1, 3]
    assert_equal 1, droll.send(:count_dice_max_thresh, results)
    
    results = [5, 9, 8]
    assert_equal 0, droll.send(:count_dice_max_thresh, results)
  end

  def test_roll
    droll = Droll.new '1d6'
    assert (0 < droll.roll.to_i) and (7 > droll.roll.to_i)

    droll = Droll.new('3N6.3')
    assert (0 <= droll.roll.to_i) and (4 > droll.roll.to_i)
  end
end
