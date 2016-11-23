use strict;
use v5.10.12;
use HTML::TableExtract;
use GD::Graph;
use WWW::Mechanize;
use Date;
use Data::Dumper;
use strict;
use GD::Graph::lines;


my($BankID, $d1, $d2) = @ARGV;
my $date1 = Date->new ($d1);
my $date2 = Date->new ($d2);

my %currencyKeys = (

    fm => {
        '52148' => 'USD',
        '52170' => 'EUR',
        '52207' => 'CNY',
        '52246' => 'JPY'
        }
    cb => {
        'R01235' => 'USD',
        'R01239' => 'EUR',
        'R01375' => 'CNY',
        'R01820' => 'JPY'
        },
    val => {
        '840' => 'USD',
        '978' => 'EUR',
        '156' => 'CNY',
        '392' => 'JPY'
        },
);

my %currencyPrices = (
    'USD' => 1,
    'EUR' => 1,
    'CNY' => 10,
    'JPY' => 100
);


sub CreateRangeBetweenDates {
  my($d1, $d2) = @_;
  my $difference;
  my @locdate;

  if ($d1->difference_month($d2) < 40) {
    $difference = $d1->difference_day($d2);
    for (my $i = 0; $i < $difference + 1; $i++) {
      $locdate[$i] = $d1->get_date();
      $d1->add_day(1);
    }
  } elsif ($d1->difference_month($d2) < 24) {
    $difference = $d1->difference_month($d2);
    for (my $i = 0; $i < $difference + 1; $i++) {
      $locdate[$i] = $d1->get_date();
      $d1->add_month(1);
    }
  } else {
    $difference = $d1->difference_year($d2);
    for (my $i = 0; $i < $difference + 1; $i++) {
      $locdate[$i] = $d1->get_date();
      $d1->add_year(1);
    }
  }
  return @locdate;
}

sub CreatePngFile {
    my $image = shift;
    my $fname = shift;

    open    (my $file, ">$fname.png") or die $!;
    binmode ($file);
    print    $file $image->png;
    close   ($file);

    return 1;
}

sub getUrl {
    my $curr = shift;
    my ($d1, $d2) = ($date1->get_date(), $date2->get_date());
    my ($m1, $y1) = ($date1->get_month(), $date1->get_year());
    my ($m2, $y2) = ($date2->get_month(), $date2->get_year());

        return "http://www.finmarket.ru/currency/rates/?id=10148&pv=1&cur=$curr&bd=$d1&bm=$m1&by=$y1&ed=$d2&em=$m2&ey=$y2&x=36&y=16#archive"
          if $BankID eq 'fm';

        return "http://www.cbr.ru/currency_base/dynamics.aspx?VAL_NM_RQ=$curr&date_req1=$d1&date_req2=$d2&rt=1&mode=1"
          if $BankID eq 'cb';

        return "http://val.ru/valhistory.asp?tool=$curr&bd=$d1&bm=$m1&by=$y1&ed=$d2&em=$m2&ey=$y2&showchartp=False"
          if $BankID eq 'val';

}

sub getAttributes {

  return  (attribs => {class => 'data'})
      if $BankID eq 'cb';

      return (attribs => {class => 'karramba'})
        if $BankID eq 'fm';

      return (  attribs => {
                    width => 433,
                    cellpadding => 6,
                }) if $BankID eq 'val';
}

sub RangeTable {
    my ($link, %atr) = @_;
    $link;
    my $html = WWW::Mechanize->new();
    $html->get($link);
    my $table = HTML::TableExtract->new(%atr);
    $table->parse($html->content());
    return $table->parse($html->content());
}

my %data;

my @dates = CreateRangeBetweenDates($date1, $date2);
$date1 = Date->new ($d1);


foreach my $key (%{$currencyKeys{$BankID}}) {
    my $table = RangeTable(getUrl($key), getAttributes);
    foreach my $value ($table->tables) {
        my (undef, @rows) = $value->rows;
        foreach my $cell(@rows) {
            push(@{$data{$currencyKeys{$BankID}{$key}}}, (($cell->[2]/$cell->[1]) * $currencyPrices{$currencyKeys{$BankID}{$key}}));
        }
    }
}


for (my $i = 0; $i < $#dates; $i++) {
    push(@{$data{date}},$dates[$i]);
}

my @graphicData = (@data{date}, @data{'USD'}, @data{'EUR'}, @data{'CNY'}, @data{'JPY'});

my %config = (
    title           => 'Rate of exchange',
    x_label         => 'Date',
    y_label         => 'currency',

    dclrs           => [ ('green', 'blue', 'red', 'black') ],

    x_label_skip    =>  1,
    x_labels_vertical => 1,
    y_label_skip    =>  1,

    y_tick_number   =>  8,
);

my $lineGraph = GD::Graph::lines->new(1200, 750);
$lineGraph->set(%config) or warn $lineGraph->error;

$lineGraph->set_legend_font('GD::gdMediumNormalFont');
$lineGraph->set_legend('JPY', 'USD', 'EUR', 'CNY');

my $lineImage = $lineGraph->plot(\@graphicData) or die $lineGraph->error;

CreatePngFile($lineImage, 'lineGraph');
