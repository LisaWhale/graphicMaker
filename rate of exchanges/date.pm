package Date; {
  use strict;
  use warnings;
  use Data::dumper;
  use v5.10;
  my @months;
  my $leap = 0;
  my @weekdays = ('sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday');
  sub new {
    my($class) = shift;
    my ($day, $month, $year) = split /\./, shift;
    $leap = check_leap($year);
    check_correct($day, $month, $year);
    my $self = {
      day=> $day,
      month=> $month,
      year=> $year,
      leap=>$leap,
      weekday=>calc_weekday($day, $month, $year),
    };

    bless $self, $class;
  }

  sub check_correct {
    my ($day, $month, $year) = @_;
    if (($day > $months[$month]) || ($month > 12) || ($year <= 0) || ($month < 0) || ($day <= 0)) {
      die "Incorrect input data!";
    }
  }

  sub days_from_newyear {
    my($self) = @_;
    check_leap($self->get_year());
    my $i = 1;
    my $sum;
    # $self->{month};
    while($self->{month} != $i) {
        $sum += $months[$i];
        $i++;
    }
    $sum += int($self->{year} * 365.2425) + $self->{day};
  }

  sub check_leap {
    my ($year) = @_;
    if ((($year % 4 == 0) && ($year % 100 != 0)) || ($year % 400 == 0)) {
      @months = (0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
      $leap = 1;
    } else {
      @months = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
      return 0;
    }
  }

  sub calc_weekday {
    my ($day, $month, $year) = @_;
    my $a = int((14 - $month) / 12);
    my $y = $year - $a;
    my $m = $month + 12 * $a - 2;
    return $weekdays[((7000 + ($day + $y + int($y/4) - int($y/100) + int($y/400) + int((31 * $m)/12)))) % 7];
 }

  sub get_day {
    my($self) = @_;
    return $self->{day};
  }

  sub get_month {
    my($self) = @_;
    return $self->{month};
  }

  sub get_year {
    my($self) = @_;
    return $self->{year};
  }

  sub get_leap {
    my($self) = @_;
    return $self->{leap};
  }

  sub get_weekday {
    my($self) = @_;
    return $self->{weekday};
  }

  sub get_date {
    my($self) = @_;
    if ($self->get_day() > $months[$self->get_month()]) {
      $self->{day} = $months[$self->get_month()];
    }
    return join ('.', ($self->get_day(), $self->get_month(), $self->get_year()));
  }

  sub check_month {
    my($self) = @_;
    if ($self->get_month() > 12) {
      $self->{month} = $self->get_month() - 12;
      $self->{year}++;
      check_leap($self->get_year());
      return 1;
    }
    return 0;
  }

  sub check_month_neg {
    my($self) = @_;
    if ($self->get_month() > 12) {
      $self->{month} = $self->get_month() - 12;
      $self->{year}++;
      check_leap($self->get_year());
    }
  }

  sub add_day {
    my($self, $amount) = @_;
    my $curr_month = $self->get_month();
    my $day_in_month = $months[$curr_month];

    if ($amount >= 0){
        if ($self->{day} + $amount > $day_in_month) {
          while ($self->{day} + $amount > $day_in_month) {
            my $left_days = ($day_in_month + 1) - $self->get_day();
            if ($amount - $left_days >= 0) {
              $amount -= $left_days;
              $self->{month}++;
              check_month($self);
              $self->{day} = 1;
            } else { $self->{day} += $amount + 1;}
            $day_in_month = $months[$self->get_month()];
          }
          $self->{day} += $amount;
        } else { $self->{day} = $self->get_day() + $amount; }
    } else {
      if ($self->{day} + $amount <= 0) {
          while ($self->{day} + $amount <= 0) {
            $amount += $self->{day};
            $self->{month}--;
            if ($self->{month} <= 0) {
              $self->{year}--;
              $self->{month} = 12;
              $self->{leap} = check_leap($self->get_year());
            }
            $self->{day} = $months[$self->get_month()];
          }
          $self->{day} += $amount;
      } else { $self->{day} += $amount; }
    }
    $self->{weekday} = calc_weekday($self->get_day(), $self->get_month(), $self->get_year());
    $self->{leap} = check_leap($self->get_year());
  }

  sub add_month {
    my($self, $amount) = @_;
    if ($amount >= 0) {
        if ($self->get_month() + $amount > 12) {
          $self->{year} = $self->get_year() + int($amount/12);
          $self->{month} = $self->get_month() + ($amount % 12);
        } else {
          $self->{month} = $self->get_month() + $amount;
        }
        check_month($self);
        if ($self->{day} > $months[$self->get_month()]) {
          $self->{day} = $months[$self->get_month()];
        }
    } else {
      if ($self->get_month() + $amount <= 0) {
        while ($self->{month} + $amount <= 0) {
          my $tmp = $amount;
          $amount += $self->{month};
          $self->{month} += $tmp;
          if($self->{month} <= 0) {
            $self->{year}--;
            $self->{month} = 12;
            $self->{leap} = check_leap($self->get_year());
          }
        }
        $self->{month} += $amount;
      } else {$self->{month} += $amount; }
    }
  }

  sub add_year {
    my($self, $amount) = @_;
    $self->{year} = $self->get_year() + $amount;
    die "Incorrect input data!" if $self->get_year() <= 0;
    check_leap($self->{year});
    return $self->get_year();
  }

  sub difference_year {
    my ($self1, $self2) = @_;
    return abs($self1->{year} - $self2->{year});
  }

  sub difference_month {
    my ($self1, $self2) = @_;
    if ($self1->get_year() != $self2->get_year()) {
      if ($self1->get_year() < $self2->get_year()) {
        return 12 * abs($self1->{year} - $self2->{year}) + ($self2->{month} - $self1->{month});
      } else { return 12 * abs($self1->{year} - $self2->{year}) + ($self1->{month} - $self2->{month}); }
    } else { return abs($self1->{month} - $self2->{month}); }
  }

  sub difference_day {
    my ($self1, $self2) = @_;
    return abs(days_from_newyear($self1) - days_from_newyear($self2));
  }

  sub set_day {
    my($self, $amount) =  @_;
    $self->{day} = $amount;
    check_correct($self->get_day(), $self->get_month(), $self->get_year());
    $self->{weekday} = calc_weekday($self->get_day(), $self->get_month(), $self->get_year());
  }

  sub set_month {
    my($self, $amount) =  @_;
    $self->{month} = $amount;
    check_correct($self->get_day(), $self->get_month(), $self->get_year());
    $self->{weekday} = calc_weekday($self->get_day(), $self->get_month(), $self->get_year());
  }

  sub set_year {
    my($self, $amount) =  @_;
    $self->{year} = $amount;
    check_correct($self->get_day(), $self->get_month(), $self->get_year());
    $self->{weekday} = calc_weekday($self->get_day(), $self->get_month(), $self->get_year());
    $self->{leap} = check_leap($self->get_year());
  }

}

1;
