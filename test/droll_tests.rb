require 'test/unit'
require '../lib/droll'

class DrollTests < Test::Unit::TestCase

  # test the process_die method

  def test_process_die_correct

    # need a hash of expected output against which to test method calls

    test_output = {
      'mod'     => '3',
      'num'     => '1',
      'sign'    => '+',
      'thresh'  => '8',
      'type'    => 'd',
      'val'     => '8'
    }

    # die codes that start with one for the number of dice or have no leading
    # numeral before the die type is specified should result in a one for
    # hash['num']; those starting with other numbers should have those numbers
    # instead

    test_droll = Droll.new('1d8+3')
    assert(
      test_droll.send(:process_die) == test_output
    )

    test_droll = Droll.new('2d8+3')
    assert(
      test_droll.send(:process_die) != test_output
    )

    implicit_num = test_droll.send(:process_die)
    assert_equal(
      implicit_num.keys.sort,
      test_output.keys.sort
    )

    assert_equal(
      implicit_num.values_at(implicit_num.keys.sort),
      test_output.values_at(test_output.keys.sort)
    )
  end


  # test the get_discrete method

  def test_get_discrete

    # need some correct values to test

    test_droll = Droll.new('1d5')
    one_to_five = test_droll.send(:get_discrete, '5')
    zero_to_five = test_droll.send(:get_discrete, '05')

    # randomness is difficult to test effectively, dammit

    assert(
      ((0 < one_to_five) and (one_to_five < 6))
    )

    assert(
      ((-1 < zero_to_five) and (zero_to_five < 6))
    )
  end


  # test the valid? method

  def test_valid?
    test_droll = Droll.new('1d6')
    assert( test_droll.send(:valid?) )

    test_droll = Droll.new('0d6')
    assert( !test_droll.send(:valid?) )
  end


  # test the roll_die method

  def test_roll_die
    test_droll = Droll.new('1d6')
    roll_die_result = test_droll.send(:roll_die, '6', 'd', '6')
    assert (0 < roll_die_result[0] and 7 > roll_die_result[0])
  end


  # test the explode_on_max_total method

  def test_explode_on_max_total
    test_droll = Droll.new('2e02')
    die_test_results = [0, 1, 2]
    assert_equal(
      [0, 1, 2],
      test_droll.explode_on_max_total(die_test_results)
    )
    assert test_droll.explode_on_max_total(die_test_results).size == 3

    die_test_results = [2, 2, 2]
    assert test_droll.explode_on_max_total(die_test_results).size > 3
  end


  # test the sum_thresh_high_dice method

  def test_sum_thresh_high_dice
    test_droll = Droll.new('3k02')
    die_test_results = [0, 1, 2]
    assert_equal 2, test_droll.sum_thresh_high_dice(die_test_results)

    test_droll = Droll.new('3k02.2')
    assert_equal 3, test_droll.sum_thresh_high_dice(die_test_results)
  end


  # test the sum_thresh_low_dice method

  def test_sum_thresh_low_dice
    test_droll = Droll.new('3K02')
    die_test_results = [0, 1, 2]
    assert_equal 0, test_droll.sum_thresh_low_dice(die_test_results)

    test_droll = Droll.new('3K02.2')
    assert_equal 1, test_droll.sum_thresh_low_dice(die_test_results)
  end


  # test the count_dice_min_thresh method

  def test_count_dice_min_thresh
    test_droll = Droll.new('10n10')
    die_test_results = (1..10).to_a
    assert_equal(
      1,
      test_droll.send(:count_dice_min_thresh, die_test_results)
    )
    
    test_droll = Droll.new('10n10.10')
    assert_equal(
      1,
      test_droll.send(:count_dice_min_thresh, die_test_results)
    )
    
    test_droll = Droll.new('6n10.6')
    die_test_results = [4, 1, 7, 2, 6, 5]
    assert_equal(
      2,
      test_droll.send(:count_dice_min_thresh, die_test_results)
    )
    
    test_droll = Droll.new('6n10.4')
    die_test_results = [3, 6, 8, 6, 8, 7]
    assert_equal(
      5,
      test_droll.send(:count_dice_min_thresh, die_test_results)
    )
    
    die_test_results = [6, 9, 7, 8, 7, 7]
    assert_equal(
      6,
      test_droll.send(:count_dice_min_thresh, die_test_results)
    )
    
    test_droll = Droll.new('3n10.7')
    die_test_results = [8, 1, 3]
    assert_equal(
      1,
      test_droll.send(:count_dice_min_thresh, die_test_results)
    )
    
    die_test_results = [6, 2, 3]
    assert_equal(
      0,
      test_droll.send(:count_dice_min_thresh, die_test_results)
    )
  end


  # test the count_dice_max_thresh method

  def test_count_dice_max_thresh
    test_droll = Droll.new('10N10')
    die_test_results = (1..10).to_a
    assert_equal(
      1,
      test_droll.send(:count_dice_max_thresh, die_test_results)
    )
    
    test_droll = Droll.new('10N10.1')
    assert_equal(
      1,
      test_droll.send(:count_dice_max_thresh, die_test_results)
    )
    
    test_droll = Droll.new('6N10.5')
    die_test_results = [4, 1, 7, 2, 6, 5]
    assert_equal(
      4,
      test_droll.send(:count_dice_max_thresh, die_test_results)
    )
    
    test_droll = Droll.new('6N10.7')
    die_test_results = [3, 6, 8, 6, 8, 7]
    assert_equal(
      4,
      test_droll.send(:count_dice_max_thresh, die_test_results)
    )
    
    die_test_results = [6, 9, 7, 8, 7, 7]
    assert_equal(
      4,
      test_droll.send(:count_dice_max_thresh, die_test_results)
    )
    
    test_droll = Droll.new('3N10.2')
    die_test_results = [8, 1, 3]
    assert_equal(
      1,
      test_droll.send(:count_dice_max_thresh, die_test_results)
    )
    
    die_test_results = [5, 9, 8]
    assert_equal(
      0,
      test_droll.send(:count_dice_max_thresh, die_test_results)
    )
  end


  # test the roll method

  def test_roll
    test_droll = Droll.new('1d6')
    assert (0 < test_droll.roll.to_i and 7 > test_droll.roll.to_i)

    test_droll = Droll.new('3N6.3')
    assert (0 <= test_droll.roll.to_i and 4 > test_droll.roll.to_i)
  end
end
