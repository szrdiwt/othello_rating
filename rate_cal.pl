
# 仕様整理

#use Thread 'async';
#use threads;
#use threads::shared;
#use Thread::Semaphore;
#use Thread::Queue;

#package threadTest;
#my $alerm :shared = 0;          #終了の合図

use Time::Local;
use Time::HiRes qw(time);
use Storable qw(lock_store lock_retrieve);

# base_data

$ddir = "./data";

$all_data     = "$ddir/all.hash";
$last_data[0] = "$ddir/last0.hash";
$last_data[1] = "$ddir/last1.hash";
$last_data[2] = "$ddir/last2.hash";
$dan_data     = "$ddir/dan_list.hash";
$dis_data     = "$ddir/dis_list.hash";
$cls_data     = "$ddir/cls_list.hash";
$idx_data     = "$ddir/idx_list.hash";
$rec_data     = "$ddir/record.hash";
$lev_data     = "$ddir/level.hash";
$sta_data     = "$ddir/statistics.hash";

#each year data
$cdir = "./common";
$ylev_data = "level.hash";
$rank_data = "rank.hash";
$rate_data = "rate.hash";
$yrec_data = "record.hash";
$slim_data = "slim.hash";
$tlist_data = "tlist.hash";


local %rate;
local %tlist;
#local %base;
local (%rep, %rname);
local $post_tdate;
local @rtime;
#local %slim;
#local %rank;


foreach (0 .. $#dan){
#	$srate{$dan[$_]} = 1450 - 50*$_;
	$srate{$dan[$_]} = 900;
	if ($srate{$dan[$_]} < 900){
		$srate{$dan[$_]} = 900;
	}
}

push ( @rtime, Time::HiRes::time() );

#パス一致＝更新時ベースレートを開いて全大会を再計算
#パス不一致＝最新レートから計算（サーバーへの負荷対策）

#open ( FH, "example.txt" );
#	while (<FH>){
#		$data .= $_;
#	}
#close(FH);

$data =~ s/　/  /g;

open (FH, "typo.txt");
while (<FH>){
	my @list = split( /,/, $_ );
	$rep{$list[1]} = $list[0];
}
close(FH);

open (FH, "name_change.txt");
while (<FH>){
	my @list = split( /,/, $_ );
	$rname{$list[0]} = $list[1];
}
close(FH);


#大会情報リストを取得

if ( $FORM{'p'} eq $passwd) {
#if ( 1 ) {

	my $postdate;
	my $t_n;
	my $modify_flag = 0;

#	%rate = %{ lock_retrieve ( "./base.hash" ) };
#	%rate = %{ lock_retrieve ( $base_data ) };


#更新作業

	if ( $FORM{'m'} eq 'c' ){
		$post_tdate = sprintf("%d%02d%02d",$FORM{'year'}, $FORM{'mon'}, $FORM{'day'} );
	}


#	print "大会リスト更新\n";

#	 sprintf("%s,%d,%s,\n", $postdate, $t_n, $FORM{'tn'} )  );
#	@tlist = sort{$b cmp $a} @tlist;
#	print @tlist;


push ( @rtime, Time::HiRes::time() );

#計算処理

	local ( %r, %rs );

	$r{1} = "win";
	$r{2} = "lose";
	$r{3} = "draw";

	$rs{1} = "○";
	$rs{2} = "×";
	$rs{3} = "△";

	print "年度別データ更新開始\n";

	my ( $psec, $pmin, $phour, $pmday, $pmon, $pyear, $pwday, $pyday )	= localtime ( time );
	$pyear += 1900;
	$pmon++;
	local $pasttime = sprintf("%d%02d%02d", $pyear-1, $pmon, $pmday);
	local ( %last, %past );
	my @dirs;
	
	opendir ( FH, $tdir );
	@dirs = grep !/\./, readdir(FH);
	close(FH);

	local $last_year = (sort{$b <=> $a} @dirs)[0];
	local $update_slim = 0;
	local $start_year = $FORM{year};

	if (! -d "$tdir/$start_year" ){
		mkdir( "$cdir/$start_year" );
		push (@dirs, $start_year);
	}

	if ( $start_year > $last_year - 1 ){
		$start_year = $last_year - 1;
	}

	foreach $year ( sort{$a <=> $b} @dirs ){
		if ( $start_year > $year  ){
			next;
		}
		print "check $year\n";
		&upyear( \%{$tlist{$year}}, $year );
		push ( @rtime, Time::HiRes::time() );
	}

	print "年度別データ更新終了\n";

	&renew_record();
#	&renew_level();
	print "統計データ 更新完了\n";
	push ( @rtime, Time::HiRes::time() );

#	%recent = %rate;
#	&make_total( \%rate, \%base );
#	&make_total( \%rate, \%past );
#	&make_total( \%rate, \%recent );
#	foreach ( sort keys %rate ){
#		print "$_,\n";
#	}
#	exit;
#	undef %rate;
#	map { $allr{$_} = $past{$_}{after};   }( keys %past   );
#	map { $allr{$_} = $recent{$_}{after}; }( keys %recent );
#	exit;

	foreach ( 1 .. $#rtime ){
		printf ( "process time: %f\n", $rtime[$_] - $rtime[$_-1] );
	}


} else {

	my %slim;
	my @dirs;
	my $last_year;

	opendir ( FH, $cdir );
	@dirs = readdir(FH);
	close(FH);
	$last_year = ( sort{$b <=> $a} @dirs)[0];
	%rate = %{lock_retrieve("$cdir/$last_year/$rate_data")};
#	map { $rate{$_}{now} = $rate{$_}{after};  }( keys %rate );
	&text2hash( \@{$slim{a}}, \%{$slim{b}}, $data );
	&up_hash( \@{$slim{a}} );
	print &sresult(\@{$slim{a}}, \%{$slim{b}}, $data);

	print "$FORM{'p'} パスワードが異なります\n";

}

1;

###########################

sub make_total {

	my ($ref1, $ref2, $all_flag) = @_;

#	$rate{$name} =;

	if ( $$ref2{dan} ){
		$$ref1{dan}     = $$ref2{dan};
	}
	if ( $$ref2{dist} ) {
		$$ref1{dist}    = $$ref2{dist};
	}

	$$ref1{after}   = $$ref2{after};
	$$ref1{win}    += $$ref2{win};
	$$ref1{lose}   += $$ref2{lose};
	$$ref1{draw}   += $$ref2{draw};
	$$ref1{ave}    += $$ref2{ave};

	if ( $$ref2{date} ){
		$$ref1{date}    = $$ref2{date};
	}

	if ( $$ref2{high} > $$ref1{high} ){
		$$ref1{high} = $$ref2{high};
	}
	if ( $$ref2{strk} > $$ref1{strk} ){
		$$ref1{strk} = $$ref2{strk};
	}
	if ( $all_flag == 0 ){
		return;
	}

	foreach $name2 ( keys %{$$ref2{player}} ){
		$$ref1{player}{$name2}{date}  = $$ref2{player}{$name2}{date};
		$$ref1{player}{$name2}{win}  += $$ref2{player}{$name2}{win};
		$$ref1{player}{$name2}{lose} += $$ref2{player}{$name2}{lose};
		$$ref1{player}{$name2}{draw} += $$ref2{player}{$name2}{draw};
		$$ref1{player}{$name2}{dr} += $$ref2{player}{$name2}{dr};
	}

	foreach (0 .. $#dan){
		my $dan = $dan[$_];
		$$ref1{pdan}{$dan}{win}  += $$ref2{pdan}{$dan}{win}; 
		$$ref1{pdan}{$dan}{lose} += $$ref2{pdan}{$dan}{lose};
		$$ref1{pdan}{$dan}{draw} += $$ref2{pdan}{$dan}{draw};
		$$ref1{pdan}{$dan}{dr}   += $$ref2{pdan}{$dan}{dr};
	}

	unshift ( @{$$ref1{hist}}, @{$$ref2{hist}} );
	push ( @{$$ref1{rec1}}, @{$$ref2{rec1}});
	push ( @{$$ref1{rec2}}, @{$$ref2{rec2}});

}

sub cal_level {
	my ($win, $lose, $draw ) = @_;
	my $level;
	my $total;

	$total = $win + $lose + $draw;

	if ( $total ){
		$level = ( $win + $draw/2 )/$total;
	}

	return ($level, $total);
}

sub cal_ilevel {
	my $dr   = $_[0];
	my $mdr  = -$dr;
	my $iad  = (32+33*(($dr/600)**2))/(1+2**($dr/100));
	my $miad = (32+33*(($mdr/600)**2))/(1+2**($mdr/100));

	return $miad / ($iad + $miad);
}

sub cal_ave( @ ) {
	my @rate = @_;
	my $count = @rate;
	my ( $average, $variance, $deviation );

	foreach ( @rate ){
		$average += $_;
	}

	$average = $average / $count;

	foreach ( @rate ){
		$variance += ($average - $_)**2
	}

	$variance = $variance / $count;
	$deviation = sqrt($variance);

	$average   = sprintf("%.1f", $average);
	$deviation = sprintf("%.1f", $deviation);

	return ($average, $deviation);
}


sub personal {

		my %last  = %{ $_[0] };
		my $ref1  = $_[1];
		my $pname = $_[2];

		foreach ( keys %{$last{player}} ){

#			my ($level1, $total1) = &cal_level( $rate{$_}{win}, $rate{$_}{lose}, $rate{$_}{draw});
			my ($level2, $total2) = &cal_level( $last{player}{$_}{win}, $last{player}{$_}{lose}, $last{player}{$_}{draw});

			my $dr_ave = $last{player}{$_}{dr}/$total2;
			my $ilevel = &cal_ilevel($dr_ave);

			my @temp;
			$temp[0]  = $_;
			$temp[1]  = int($rate{$_}{now});
			$temp[2]  = int($total2);
			$temp[3]  = int($last{player}{$_}{win});
			$temp[4]  = int($last{player}{$_}{lose});
			$temp[5]  = int($last{player}{$_}{draw});
			$temp[6]  = sprintf("%.3f", $level2);
			$temp[7]  = int($dr_ave);
			$temp[8]  = sprintf("%.3f", $ilevel);
			$temp[9]  = sprintf("%.3f", $level2/$ilevel );
			$temp[10] = $last{player}{$_}{date};

#			$temp[7]  = int($total1);
#			$temp[8]  = int($rate{$_}{win});
#			$temp[9]  = int($rate{$_}{lose});
#			$temp[10] = int($rate{$_}{draw});
#			$temp[11] = sprintf("%.3f", $level1);

			push ( @{$$ref1[1]}, \@temp);
		}

		foreach (0 .. $#dan){
			my $dan = $dan[$_];

#			print "$name $dan $last{pdan}{$dan}{lose} $last{pdan}{'八段'}{lose}\n";
			my ($level, $total) = &cal_level( $last{pdan}{$dan}{win}, $last{pdan}{$dan}{lose}, $last{pdan}{$dan}{draw});

			if ( !$total ){
				next;
			}

			my $dr_ave = $last{pdan}{$dan}{dr}/$total;
			my $ilevel = &cal_ilevel($dr_ave);
			my @temp;

			#print "$pname $dr_ave\n";

			$temp[0] = $dan;
			$temp[1] = int($total);
			$temp[2] = int($last{pdan}{$dan}{win});
			$temp[3] = int($last{pdan}{$dan}{lose});
			$temp[4] = int($last{pdan}{$dan}{draw});
			$temp[5] = sprintf("%.3f", $level);
			$temp[6]  = int($dr_ave);
			$temp[7]  = sprintf("%.3f", $ilevel);
			$temp[8]  = sprintf("%.3f", $level/$ilevel );

			push ( @{$$ref1[2]}, \@temp );
		}

		$$ref1[3] = \@{$last{hist}};

		my (@prec, @temp);

		$prec[0] = \@{$last{rec1}};
		$prec[1] = \@{$last{rec2}};

		@{$prec[2][0]} = ( sort { $prec[0][$b][4] <=> $prec[0][$a][4] } (0 .. $#{$prec[0]}) );
		@{$prec[2][1]} = ( sort { $prec[0][$a][4] <=> $prec[0][$b][4] } (0 .. $#{$prec[0]}) );
		@{$prec[2][2]} = ( sort { $prec[1][$b][5] <=> $prec[1][$a][5] } (0 .. $#{$prec[1]}) );
		@{$prec[2][3]} = ( sort { $prec[1][$a][5] <=> $prec[1][$b][5] } (0 .. $#{$prec[1]}) );

		my $thend1 = @{$prec[0]} - 1;
		my $thend2 = @{$prec[1]} - 1;

		if ( $thend1 > 29 ){
			$thend1 = 29;
		}

		if ( $thend2 > 29 ){
			$thend2 = 29;
		}

		foreach ( 0 .. $thend1 ) {
			if ( $prec[0][$prec[2][0][$_]][4] < 0 ){ last; }
			push (@{$temp[0]}, \@{$prec[0][$prec[2][0][$_]]} );
		}

		foreach ( 0 .. $thend1 ) {
			if ( $prec[0][$prec[2][1][$_]][4] > 0 ){ last; }
			push (@{$temp[0]}, \@{$prec[0][$prec[2][1][$_]]} );
		}

		foreach ( 0 .. $thend2 ) {
			if ( $prec[1][$prec[2][2][$_]][5] < 0 ){ last; }
			push (@{$temp[1]}, \@{$prec[1][$prec[2][2][$_]]} );
		}

		foreach ( 0 .. $thend2 ) {
			if ( $prec[1][$prec[2][3][$_]][5] > 0 ){ last; }
			push (@{$temp[1]}, \@{$prec[1][$prec[2][3][$_]]} );
		}

		$$ref1[4][0] = \@{$temp[0]};
		$$ref1[4][1] = \@{$temp[1]};

#		lock_store( \@pdata,  "$pdir\/$pname.hash" );

}

sub make_index {
	my $ref = $_[0];
#	my $l   = $_[1];
	my $p;

#	print "index 作成 \n";

	foreach $l ( 0 .. $#{$$ref[0]} ){

#		print "index 作成 r: $$ref[0][$l][1] n: $$ref[0][$l][2]\n";

		my $f = 0;
		foreach ( 1 .. $#{$$ref[0][$l]} ) {
			$f = 1;
#			print "mi : $l $$ref[0][$l][$_]\n";
			if ( $$ref[0][$l][$_] eq "" ){
				$f = 0;
				last;
			}
		}
		if ( $f == 1){
			$p = $l;
			last;
		}
	}

	foreach $s ( 1 .. $#{$$ref[0][$p]}) {
		my $sample = $$ref[0][$p][$s];
		my (@list1, @list2);
		if ( $sample =~ /^-?\d+$/ ){
			@list1 =	sort {$$ref[0][$b][$s] <=> $$ref[0][$a][$s]}(0 .. $#{$$ref[0]});
			$$ref[1][$s][0] = \@list1;
#			push ( @{$$ref[1][$s]}, @list1 );
			@list2 =	sort {$$ref[0][$a][$s] <=> $$ref[0][$b][$s]}(0 .. $#{$$ref[0]});
			$$ref[1][$s][1] = \@list2;
#			print "$s $last[1][$s][0]\n";
		} else {
			@list1 =	sort {$$ref[0][$b][$s] cmp $$ref[0][$a][$s]}(0 .. $#{$$ref[0]});
			$$ref[1][$s][0] = \@list1;
			@list2 =	sort {$$ref[0][$a][$s] cmp $$ref[0][$b][$s]}(0 .. $#{$$ref[0]});
			$$ref[1][$s][1] = \@list2;
		}
	}

}

sub make_data {

# format : memo
# 0 : name scholar
# 1 : dan  scholar
# 2 : dis  scholar
# 3 : game array
# 4 : win  scholar
# 5 : lose scholar
# 6 : draw scholar
# 7 : st   scholar
# 8 : high scholar
# 9 : ave  scholar

	my $ref1  = $_[0];
	my $ref2  = $_[1];
	my $ref3  = $_[2];
	my @slim  = @{$_[3]};
	my $n     = $_[4];
	my $date  = $_[5];
	my $tname = $_[6];

#	$$ref1{win}  += $slim[4][$n];
#	$$ref1{lose} += $slim[5][$n];
#	$$ref1{draw} += $slim[6][$n];

	my %tr;

#	if ( $slim[5][$n] == 0 and $slim[6][$n] == 0 ){
#		$$ref1{st} += $slim[7][$n];
#	} else {
#		$$ref1{st} = $slim[7][$n];
#	}

#	if ($$ref1{st} > $$ref1{strk}){
#		$$ref1{strk} = $$ref1{st};
#	}

#	if ( $slim[8][$n] > $$ref1{high} ){
#		$$ref1{high} = $slim[8][$n];
#	}

#	$$ref1{ave} += $slim[9][$n];

	my $player1 = $slim[0][$n];
#	my $prate1  = $slim[0][$n];

	if ( $slim[1][$n] ){
		$$ref1{dan}  = $slim[1][$n];
	}

	if ( $slim[2][$n] ){
		$$ref1{dist} = $slim[2][$n];
	}

#	print "check!! data $player1\n";

	foreach $i ( 1 .. $#{$slim[3]} ){

#	print "check!! data1 $player1\n";

		if ( $slim[3][$i][$n][1] ){

			my $m = $slim[3][$i][$n][0];
			my $player2 = $slim[0][$m];
			my $dan2    = $slim[1][$m];
			my $result  = $slim[3][$i][$n][1];
			my $rkey    = $r{$result};
			my $now1 = $slim[3][$i-1][$n][2];
			my $now2 = $slim[3][$i-1][$m][2];
			my $dr = $now1 - $now2;
			my $diff = int($dr/10);
			my $nowr = $slim[3][$i][$n][2];

			$$ref1{player}{$player2}{$rkey}++;
			$$ref1{player}{$player2}{dr} += $dr;
			$$ref1{pdan}{$dan2}{$rkey}++;
			$$ref1{pdan}{$dan2}{dr} += $dr;
			$$ref1{$rkey}++;
			$tr{$rkey}++;

#			print "$result $dan2 $player2 $rkey $$ref1{pdan}{$dan2}{$rkey}\n";

			$$ref1{player}{$player2}{date} = $date;
			$$ref1{ave} += $nowr;
			if ( $nowr > $$ref1{high} ){
				$$ref1{high} = $nowr;
			}

			if ( $result == 1 ){
				if ( $nst > 0 ){
					$nst++;
				} else {
					$nst = 1;
				}
			} elsif ($result == 2) {
				if ( $nst < 0 ){
					$nst--;
				} else {
					$nst = -1;
				}
			} else {
				$nst = 0;
			}

			if ($nst > $$ref1{strk}){
				$$ref1{strk} = $nst;
			}

			if ( $dr > 0 ){
				$$ref3{sort1}{$diff}{$rkey}++;
				push(@{$$ref3{sort2}}, "$dr:$rkey");
#				push(@{$$ref2[3]}, "$dr:$rkey");
			}

			if ( $result == 1 and $dr < 0 ){
				my @temp;
				$temp[1] = $player1;
				$temp[2] = $player2;
				$temp[3] = int($now1);
				$temp[4] = int($now2);
				$temp[5] = sprintf("%.2f", -$dr);
				$temp[6] = $date;
				$temp[7] = $tname;
				push ( @{$$ref1{rec2}}, \@temp );

				if ( abs($dr) > 0 ){
					push ( @{$$ref2[1]}, \@temp );
				}
			} elsif ( $result == 2 and $dr > 0 ) {
				my @temp;
				$temp[1] = $player2;
				$temp[2] = $player1;
				$temp[3] = int($now2);
				$temp[4] = int($now1);
				$temp[5] = sprintf("%.2f", -$dr);
				$temp[6] = $date;
				$temp[7] = $tname;
				push ( @{$$ref1{rec2}}, \@temp );
			}

			my @hdata;

			$hdata[0] = sprintf("%s",$date);
			$hdata[1] = $tname;
			$hdata[2] = $player2;
			$hdata[3] = $rs{$result};
			$hdata[4] = sprintf("%4d -> %4d", $slim[3][$i-1][$n][2], $slim[3][$i][$n][2] );
			$hdata[5] = sprintf("%d", $slim[3][$i-1][$m][2] - $slim[3][$i-1][$n][2] );
			$hdata[6] = sprintf("%d", $slim[3][$i][$n][2] - $slim[3][$i-1][$n][2] );
			unshift ( @{$$ref1{hist}}, \@hdata );

#			$$ref{player}{}
		}
	}

	my @temp;
	my $di = $slim[3][$#{$slim[3]}][$n][2] - $slim[3][0][$n][2];
	$temp[1] = $player1;
#	$temp[2] = sprintf("%2d勝%2d敗%2d分", $slim[4][$n], $slim[5][$n], $slim[6][$n]);
	$temp[2] = sprintf("%2d勝%2d敗%2d分", $tr{win}, $tr{lose}, $tr{draw});
	$temp[3] = sprintf("%4d -> %4d", $slim[3][0][$n][2], $slim[3][$#{$slim[3]}][$n][2]);
	$temp[4] = sprintf("%.2f", $di );
	$temp[5] = $date;
	$temp[6] = sprintf("%s", $tname);
	push (@{$$ref1{rec1}}, \@temp);

	if ( abs($di) > 0 ){
		push (@{$$ref2[0]}, \@temp);
	}

#	foreach ( 1 .. 6 ){
#		print $temp[$_];
#	}
#	print "\n";

}

sub make_last {
	my $ref1 = $_[0];
	my @slim = @{$_[1]};
	my $n    = $_[2];
	my $date = $_[3];
	
	$date =~ s/_\d+$//;
	$$ref1{after} = $slim[3][$#{$slim[3]}][$n][2];
#	$$ref1{dan}   = $slim[1][$n];
#	$$ref1{dist}  = $slim[2][$n];
	$$ref1{date}  = $date;
}

sub pupdate {

	my ( $name ) = @_;

#	while ( $name = $queue->dequeue ){

	my ( %las, %pas );
	my ( %year1, %year2, %year);
	my $tf;
	my $lt = ${$rate{$name}{date}}[$#{$rate{$name}{date}}];

	local $nst = $rate{$name}{st};

# year1 は1年以上前のデータを記録
# year2 は1年以内のデータ

	my $pt;

	while ( $tf = shift( @{$rate{$name}{date}} ) ){
		my @t  = split(/_/, $tf);
		my @tt = split(/-/, $t[0]);
		my $ttime = sprintf("%d%02d%02d", $tt[0], $tt[1], $tt[2]);

#		print "check!! $name  $slim{$tf}{b}{$name}, $t[0], $tf \n";

		if (  $ttime < $pasttime  ){
			&make_data( \%{$year1{$tt[0]}}, \@{$record{$tt[0]}}, \%{$per{$tt[0]}}, \@{$slim{$tf}{a}}, $slim{$tf}{b}{$name}, $t[0], $tf );
			$pt = $tf;
		} else {
			&make_data( \%{$year2{$tt[0]}}, \@{$record{$tt[0]}}, \%{$per{$tt[0]}}, \@{$slim{$tf}{a}}, $slim{$tf}{b}{$name}, $t[0], $tf );
		}
	}

#	print "check!! $name $ld $post_tdate\n";
#	&make_total ( \%past, \%{$base{$name}} );
	foreach ( keys %year1 ){
		&make_total( \%pas, \%{$year1{$_}} );
		%{$year{$_}} = %{$year1{$_}};
	}


	foreach ( keys %year2 ){
		&make_total( \%las, \%{$year2{$_}} );
		if ( %{$year{$_}} ){
			&make_total( \%{$year{$_}}, \%{$year2{$_}}, 1 );
		} else {
			%{$year{$_}} = %{$year2{$_}};
		}
	}

	&make_last ( \%las, \@{$slim{$lt}{a}}, $slim{$lt}{b}{$name}, $lt );
	my $ld = $las{date};
	$ld =~ tr/-//d;


		my $win  = $las{win}  + $pas{win};
		my $lose = $las{lose} + $pas{lose};
		my $draw = $las{draw} + $pas{draw};

		my ($high, $streak);
		if ( $las{high} > $pas{high} ){
			$high = $las{high};
		} else {
			$high = $pas{high};
		}
		if ( $las{strk} > $pas{strk} ){
			$streak = $las{strk};
		} else {
			$streak = $pas{strk};
		}

# 年度末のデータを更新
		$rate{$name}{after} = $las{after};
		$rate{$name}{win}  += $win;
		$rate{$name}{lose} += $lose;
		$rate{$name}{draw} += $draw;

		if ( $high > $rate{$name}{high} ){
			$rate{$name}{high}  = $high;
		}
		if ( $streak > $rate{$name}{strk} ){
			$rate{$name}{strk}  = $streak;
		}
		$rate{$name}{st}    = $nst;

		if ( $pt ){
			$pt =~ s/_\d+$//;
			$rate{$name}{pdate} = $pt;
		}

		&make_total( \%{$past{$name}}, \%pas );

		if ( $ld >= $pasttime ){
			&make_total( \%{$last{$name}}, \%las );
		}


	my %pdata;
	foreach ( keys %year ){
#		print "$_ $name.hash $l\n";

		my $ywin  = $year{$_}{win};
		my $ylose = $year{$_}{lose};
		my $ydraw = $year{$_}{draw};
			
		my ( $level,  $total  ) = &cal_level( $ywin, $ylose, $ydraw );

		if ( $total ){
			$year{$_}{ave} = $year{$_}{ave}/$total;
		} else {
			next;
		}
			
#			print "$_ $total $name $win $lose $draw $year{$_}{ave}\n";

		my ( $start, $end );

		if ( $#{$year{$_}{rec1}} == 0 ) {
			my $temp = ${$year{$_}{rec1}}[0][3];
			$temp =~ /(\d+)\s+->\s+(\d+)/;
			$start = $1;
			$end   = $2;
		} else {
			$start = ${$year{$_}{rec1}}[0][3];
			$start =~ s/\s+->\s+\d+$//;
			$end   = ${$year{$_}{rec1}}[$#{$year{$_}{rec1}}][3];
			$end =~ s/^\d+\s+->\s+//;
		}

		my @temp;

		$temp[ 1] = sprintf("%s", $name );;
		$temp[ 2] = sprintf("%d", $total);
		$temp[ 3] = sprintf("%d", $ywin);
		$temp[ 4] = sprintf("%d", $ylose);
		$temp[ 5] = sprintf("%d", $ydraw);
		$temp[ 6] = sprintf("%.3f", $level);
		$temp[ 7] = sprintf("%d", $year{$_}{high});
		$temp[ 8] = sprintf("%d", $year{$_}{ave});
		$temp[ 9] = sprintf("%d", $year{$_}{strk});
		$temp[10] = sprintf("%d -> %d", $start, $end);
		$temp[11] = sprintf("%d", $end - $start);
		push (@{$rank{$_}}, \@temp);

		push (@year_rate, $end);
		$per{$_}{sta}{game} += $total;

		if ( $total == ( $rate{$name}{win} + $rate{$name}{lose} + $rate{$name}{draw} ) ){
			printf ("newp $_ $name %d %d\n", $total, ( $rate{$name}{win} + $rate{$name}{lose} + $rate{$name}{draw} ) );
			$per{$_}{sta}{newp}++;
		}

#			$slim[3][$i][$n][2]
#			$rank{$_}{$name}

		if ( $ld >= $post_tdate ) {
# 投稿日以降に出場した人の個人データを更新
# $post_tdate がないときは 全員分を更新。
#	&personal( \%last, $name );
#	&personal( \%last, $name );
			my $write_name = $name;
			&personal( \%{$year{$_}}, \@{$pdata{$_}}, $name );
			${$pdata{$_}}[5] = \@temp;
			&encode(\$write_name);
			lock_store( \@{$pdata{$_}},  "$pdir/$_/$write_name.hash" );
			print "$_ $name $write_name.hash $l\n";
		}
	}



# 動作様子見のため一旦戻る

#		if ( $ld < $pasttime ){
#			delete( $last{$name} );
#		} else {
#			&make_total( \%{$last{$name}}, \%las );
#		}

		return;

#	}
#	foreach $i ( 0 .. $#{$last1[0]} ){
#		print "i $_\n";
#		foreach ( @{$last1[0][$i]} ){
#			print "$_\n";
#		}
#	}

}


sub upyear {

	my %tlist = %{ $_[0] };
	my $year = $_[1];

	local ( %per, %record, @year_rate );
	local ( %slim, %rate, %rank );

	if (! -d "$cdir/$year" ){
		mkdir( "$cdir/$year" );
	}

	if (! -d "$tdir/$year" ){
		mkdir( "$tdir/$year" );
	}

	if (! -d "$pdir/$year" ){
		mkdir( "$pdir/$year" );
	}

	if (! -d "$tldir/$year" ){
		mkdir( "$tldir/$year" );
	}

	eval{ %slim  = %{ lock_retrieve ( "$cdir/$year/$slim_data" ) } };

	if (!eval{ %rate = %{ lock_retrieve ( sprintf("$cdir/%d/$rate_data", $year - 1) )}}){

		if ( $year != 2003 ){
			print "レートデータが存在しません。再構築してください。\n";
			exit;
		}

		if (! -d "$cdir/2002" ){
			mkdir( "$cdir/2002" );
		}

		open (FH, "base_200309.txt");
		while (<FH>){
			
			my @t = split(/,/, $_);
			if ( exists($rep{$t[1]}) ){
				$t[1] = $rep{$t[1]};
			}

#			$rate{$t[1]}{visible} = $t[3];
			$rate{$t[1]}{now}    = $t[0];
			$rate{$t[1]}{after}  = $t[0];
			$rate{$t[1]}{dan}    = $t[2];
			$rate{$t[1]}{dist}   = $t[3];
			$rate{$t[1]}{win}    = $t[4];
			$rate{$t[1]}{lose}   = $t[5];
			$rate{$t[1]}{draw}   = $t[6];
			$rate{$t[1]}{high}   = $t[7];
			$rate{$t[1]}{strk}   = $t[8];
			
			my ( $level, $total) = &cal_level( $t[4], $t[5], $t[6] );
			my @temp;

			$temp[ 1] = sprintf("%s", $t[1] );
			$temp[ 2] = sprintf("%d", $total);
			$temp[ 3] = sprintf("%d", $t[4]);
			$temp[ 4] = sprintf("%d", $t[5]);
			$temp[ 5] = sprintf("%d", $t[6]);
			$temp[ 6] = sprintf("%.3f", $level);
			$temp[ 7] = sprintf("%d", $t[7]);
			$temp[ 8] = sprintf("%s", "N/A");
			$temp[ 9] = sprintf("%d", $t[8]);
			$temp[10] = sprintf("%d -> %d", 900, $t[0]);
			$temp[11] = sprintf("%d", $t[0] - 900 );

			print "$t[1]\n";
			&encode(\$t[1]);
#			print "$t[1]\n";
			lock_store( \@temp, "$odir/$t[1].hash" );
#			print "$t[1]\n";
		}
		close(FH);

		lock_store( \%rate, sprintf("$cdir/%d/$rate_data", $year - 1) );

		print "$year rate data 生成\n";
	}

	open (FH, "$tdir/$year.txt");
	eval 'flock ( FH, 1 )';
	seek ( FH, 0, 0 );
	while (<FH>){
		my @t = split(/,/, $_);
		my $tf = sprintf("%s_%s", $t[0], $t[1]);
		if ($FORM{'m'} eq "d" and $FORM{$tf} eq "1"){
			unlink("$tdir/$year/$tf.txt");
			unlink("$tldir/$year/$tf.html");
			next;
		} elsif ( $FORM{'m'} eq "c" and $FORM{'tl'} eq $tf){
#			$tlist{$t[0]}{$t[1]} = $FORM{'tn'};
			unlink("$tdir/$year/$tf.txt");
			unlink("$tldir/$year/$tf.html");
			next;
		} else {
			my $year = (split( /-/, $t[0]))[0];
			$tlist{$t[0]}{$t[1]} = $t[2];
		}
	}
	eval 'flock ( FH, 8 )';
	close (FH);

	if ( $FORM{'m'} eq 'c' and $FORM{'year'} == $year ){

		$t_n = 0;
		$postdate = sprintf("%d-%02d-%02d", $FORM{'year'}, $FORM{'mon'}, $FORM{'day'});
		foreach ( sort {$a <=> $b} keys %{$tlist{$postdate}} ){
			if ( $_-1 != $t_n ){
				last;
			}

			$t_n = $_;
	#		print "t_n $t_n\n";
		}
		$t_n++;
		$tlist{$postdate}{$t_n} = $FORM{'tn'};

#		$post_tdate = timelocal( 0, 0, 0, $FORM{'day'}, $FORM{'mon'}-1 , $FORM{'year'}-1900);
#		$post_tdate = sprintf("%d%02d%02d",$FORM{'year'}, $FORM{'mon'}, $FORM{'day'} );
#		my $temp = $data;

		open(FH,"> $tdir/$year/$postdate\_$t_n.txt");
		eval 'flock (FH,2)';
		truncate (FH,0);
		seek (FH,0,0);
		print FH $data;
		close(FH);
	}


	my %wtlist;

	open(FH,"> $tdir/$year.txt");
	eval 'flock (FH,2)';
	truncate (FH,0);
	seek (FH,0,0);
	foreach $date ( sort{$b cmp $a} keys %tlist ){
		foreach ( sort{$b <=> $a} keys %{$tlist{$date}} ){
			print FH sprintf("%s,%d,%s,\n", $date, $_, $tlist{$date}{$_} );
#			my $tref = "$date\_$_";
#			$tref =~ s/-//g;
#			$wtlist{link}{$tref} = sprintf("%s/%s_%d.txt", $tldir, $date, $_);
			$wtlist{link}{sprintf("%s_%d",$date,$_)} = sprintf("%s/%d/%s_%d.html", $tldir, $year, $date, $_);
			$wtlist{sort}{sprintf("%s_%d",$date,$_)} = $tlist{$date}{$_};
			$per{$year}{sta}{tn}++;
		}
	}
	close(FH);

#年度別大会リストデータ
	lock_store( \%wtlist, "$cdir/$year/$tlist_data" );

	foreach $tf ( keys %slim ){
		if ($FORM{'m'} eq "d" and $FORM{$tf} eq "1"){
			delete( $slim{$tf} );
			$update_slim = 1;
		} elsif ( $FORM{'m'} eq "c" and $FORM{'tl'} eq $tf){
			delete( $slim{$tf} );
			$update_slim = 1;
		}
	}

	foreach $date ( sort{$a cmp $b} keys %tlist ){
		foreach $num ( sort{$a <=> $b} keys %{$tlist{$date}} ){
			my $tf = "$date\_$num";

			if ( !$slim{$tf} ){
				my $tdata;
				open (FH, "$tdir/$year/$tf.txt") or print "read error!! $tdir, $date, $num\n";
				while (<FH>){
					$tdata .= $_;
				}
				close (FH);
				&text2hash( \@{$slim{$tf}{a}}, \%{$slim{$tf}{b}}, $tdata );
				$update_slim = 1;
			}

			my $ld = $date;
			$ld =~ tr/-//d;

			if (( $ld >= $post_tdate and $post_tdate != 0 ) or $update_slim ) {
#			if ( timelocal( 0, 0, 0, $ld[2], $ld[1]-1 , $ld[0]-1900 ) >= $post_tdate ) {
				my $tdata;

				&up_hash( \@{$slim{$tf}{a}} );

				print "更新： $tlist{$date}{$num} $ld $post_tdate\n";
				open (FH, sprintf("%s/%d/%s_%d.txt", $tdir, $year, $date, $num )) or print "read error!! $tdir, $year, $date, $num\n";
				while (<FH>){
					$tdata .= $_;
				}
				close (FH);

				open(FH,"> $tldir/$year/$date\_$num.html");
				eval 'flock (FH,2)';
				truncate (FH,0);
				seek (FH,0,0);
#				print FH sprintf("%s %s\n", $tlist{$date}{$num}, $date);
				print FH &sresult2(\@{$slim{$tf}{a}}, \%{$slim{$tf}{b}}, $tdata);
				close(FH);
			}

			&slim2rate( \@{$slim{$tf}{a}}, $tf );
#			print "更新： $tlist{$date}{$num}\n";
#			exit;
		}
	}

	if ( $update_slim ){
#		foreach ( keys %slim ){
#			print "$_\n";
#		}
#		print "slim 大会データ更新";
		lock_store( \%slim, "$cdir/$year/$slim_data" );
		print "$year slim データ更新\n";
	}

	my @plist = keys %rate;

#	foreach ( sort keys %slim ){
#		print "test $_\n";
#	}

	foreach $n ( 0 .. $#plist ){
		my $name = $plist[$n];

		if ( !$name ){
			next;
		}

		if ( $year == $start_year ){
			&make_total( \%{$past{$name}}, \%{$rate{$name}} );
		}

		if ( @{$rate{$name}{date}} == 0 ){
			next;
		}

		my $lt = ${$rate{$name}{date}}[$#{$rate{$name}{date}}];
		my @t  = split(/_/, $lt);
		my @tt = split(/-/, $t[0]);
		my $ld = sprintf("%d%02d%02d", $tt[0], $tt[1], $tt[2]);

		if ( $pasttime > $ld and $update_slim == 0 ){
			next;
		}

#		print "$year $name $update_slim\n";

		&pupdate( $name );

#		$lnum{$name} = $l;
#		$queue->enqueue($name);
#		$l++;
	}

	print "$year レートデータ更新\n";
#	lock_store( \%rate, "$cdir/$year/rate.hash" );

	if ( $update_slim == 0 ){
		return;
	}

	my @temp = @{$record{$year}};
	my @temp2;

	@{$temp2[2][0]} = ( sort { $temp[0][$b][4] <=> $temp[0][$a][4] } (0 .. $#{$temp[0]}) );
	@{$temp2[2][1]} = ( sort { $temp[0][$a][4] <=> $temp[0][$b][4] } (0 .. $#{$temp[0]}) );
	@{$temp2[2][2]} = ( sort { $temp[1][$b][5] <=> $temp[1][$a][5] } (0 .. $#{$temp[1]}) );

	foreach ( 0 .. 149 ) {
		if ( $temp[0][$temp2[2][0][$_]][4] > 0 ){
			push (@{$temp2[0]}, \@{$temp[0][$temp2[2][0][$_]]} );
		} else {
			last;
		}
	}

	foreach ( 0 .. 149 ) {
		if ( $temp[0][$temp2[2][1][$_]][4] < 0 ){
			push (@{$temp2[0]}, \@{$temp[0][$temp2[2][1][$_]]} );
		} else {
			last;
		}
	}

	my $cnt2 = 149;
	if ( $cnt2 > @{$temp[1]} - 1 ){
		$cnt2  = @{$temp[1]} - 1;
	}
	foreach ( 0 .. $cnt2 ) {
		push (@{$temp2[1]}, \@{$temp[1][$temp2[2][2][$_]]} );
	}

	@{$temp[0]} = @{$temp2[0]};
	@{$temp[1]} = @{$temp2[1]};

#	@{$temp[2][0]} = ( sort { $temp[0][$b][4] <=> $temp[0][$a][4] } (0 .. $#{$temp[0]}) );
#	@{$temp[2][1]} = ( sort { $temp[0][$a][4] <=> $temp[0][$b][4] } (0 .. $#{$temp[0]}) );
#	@{$temp[2][2]} = ( sort { $temp[1][$b][5] <=> $temp[1][$a][5] } (0 .. $#{$temp[1]}) );

	( $per{$year}{sta}{ave}, $per{$year}{sta}{sd} ) = &cal_ave( @year_rate );
	$per{$year}{sta}{allp} = @year_rate;

	lock_store( \%rate,             "$cdir/$year/$rate_data" );
	lock_store( \@{$rank{$year}},   "$cdir/$year/$rank_data" );
	lock_store( \%{$per{$year}},    "$cdir/$year/$ylev_data" );
#	lock_store( \@{$record{$year}}, "$cdir/$year/$yrec_data" );
	lock_store( \@temp, "$cdir/$year/$yrec_data" );
	print "$year 各データ更新\n";

	if ( $year == $last_year ){
#		print "last です\n";
		&update;
	}
#

}

sub update {
	my( @tmp );

#	local ( %lnum, %pnum );
#	local ( @last1,@last2, @last3, %ldan, %ldis, %lddd);
#	local ( %rate_list, %write_data );
#	local %per;
#	local @record;
#	local @rdiff;

	local ( %lnum, %pnum );
	local ( @last1, @last2, @last3, %ldan, %ldis, %lddd);
	local ( %rate_list, %write_data );

	my $l = 0;

	foreach $name ( keys %last ){

		my %rat = %{$rate{$name}};
		my %las = %{$last{$name}};
		my %pas = %{$past{$name}};

		my @temp;
		my ( $level,  $total  ) = &cal_level( $rat{win}, $rat{lose}, $rat{draw});
		my ( $rlevel, $rtotal ) = &cal_level( $las{win}, $las{lose}, $las{draw});
		my ( $plevel, $ptotal ) = &cal_level( $pas{win}, $pas{lose}, $pas{draw});

		if ( $rtotal ){
			$las{ave} = $las{ave}/$rtotal;
		}

#		if ( $ptotal ){
#			$pas{ave} = $pas{ave}/$ptotal;
#		}

		push ( @{$rate_list{total}},      $las{after} );
		push ( @{$rate_list{$las{dan}}},  $las{after} );
		push ( @{$rate_list{$las{dist}}}, $las{after} );

		$temp[ 1] = sprintf("%s", $name );
		$temp[ 2] = $las{dan};
		$temp[ 3] = $las{dist};
		$temp[ 4] = sprintf("%d", $las{after});
		$temp[ 5] = sprintf("%d", $total);
		$temp[ 6] = sprintf("%d", $rat{win});
		$temp[ 7] = sprintf("%d", $rat{lose});
		$temp[ 8] = sprintf("%d", $rat{draw});
		$temp[ 9] = sprintf("%.3f", $level);
		$temp[10] = sprintf("%d", $rat{high});
		$temp[11] = sprintf("%d", $rat{strk});
		$temp[12] = $las{date};

		push( @{$last1[$l]}, @temp );

#		foreach ( @temp ){
#			print "$_,";
#		}
#		print "\n";

#		push( @{$$ref[0][$l]}, @temp );
#			$last1[0][$l] = \@temp;
#			print @temp;
#			print "\n";
#		push( @{$last3[0][$n]}, @temp );

		$temp[ 5] = sprintf("%d", $ptotal);
		$temp[ 6] = sprintf("%d", $pas{win});
		$temp[ 7] = sprintf("%d", $pas{lose});
		$temp[ 8] = sprintf("%d", $pas{draw});
		$temp[ 9] = sprintf("%.3f", $plevel);
		$temp[10] = sprintf("%d", $pas{high});
		$temp[11] = sprintf("%d", $pas{strk});
		$temp[12] = $rat{pdate};
		push ( @{$last2[$l]}, @temp );

		my $streak = $rat{st};
		if ($rat{st} > 0){
			$streak = "+" . $rat{st};
		}

		$temp[ 5] = sprintf("%s", $streak);
		$temp[ 6] = sprintf("%d", $rtotal);
		$temp[ 7] = sprintf("%d", $las{win});
		$temp[ 8] = sprintf("%d", $las{lose});
		$temp[ 9] = sprintf("%d", $las{draw});
		$temp[10] = sprintf("%.3f", $rlevel);
		$temp[11] = sprintf("%d", $las{high});
		$temp[12] = sprintf("%d", $las{ave});
		$temp[13] = sprintf("%d", $las{strk});
		$temp[14] = $las{date};
		push ( @{$last3[$l]}, @temp );

		push ( @{ $ldan{$las{dan}}{list} },  $l );
		push ( @{ $ldis{$las{dist}}{list} }, $l );
		push ( @{ $lddd{$las{dist}}{$las{dan}}{int($las{after}/10)} }, $l );

		$lnum{$name} = $l;
		$l++;

	}
	print "data index 作成開始\n";

#   name index 生成処理
#	%{$last1[2]} = %lnum;
#	%{$last2[2]} = %lnum;

#	&make_index(\@last1, $l-1 );
#	&make_index(\@last2, $l-1 );

	foreach $dan ( @dan ){
		if ( !$dan ){ next; }
#		print "$dan @{$rate_list{$dan}}\n";
		my ( $ave, $sd ) = &cal_ave( @{$rate_list{$dan}} );
		$ldan{$dan}{ave} = $ave;
		$ldan{$dan}{sd} = $sd;
	}
#	print "data index 作成開始\n";

	foreach $dist ( @dist ){
		if ( !$dist ){ next; }
		my ( $ave, $sd ) = &cal_ave( @{$rate_list{$dist}} );
		$ldis{$dist}{ave} = $ave;
		$ldis{$dist}{sd}  = $sd;
	}

	my %all;
	foreach ( keys %rate ){
		if ( $rate{$_}{after} ){
			$all{$_} = $rate{$_}{after};
		}
	}

	push ( @rtime, Time::HiRes::time() );

	print "data 更新開始\n";

	lock_store( \%all,  $all_data );
	lock_store( \@last3, $last_data[0] );
	lock_store( \@last2, $last_data[1] );
	lock_store( \@last1, $last_data[2] );
	lock_store( \%ldan, $dan_data );
	lock_store( \%ldis, $dis_data );
	lock_store( \%lddd, $cls_data );
	lock_store( \%lnum, $idx_data );

	print "data 更新完了\n";

	return;


	require "fly.pl";

	my ( $whole_ave, $whole_sd ) = &cal_ave( @{$rate_list{total}} );
	my %gdata;
	foreach (@{$rate_list{total}} ){
		my $a = $_/10;
		if ($a){
			$gdata{int($a)}++;
		}
	}

	&make_gif("graph.gif", $whole_ave, $whole_sd, %gdata);

	print "画像生成完了\n";

}

sub renew_record {
	my ( @temp, @temp2 );
#	my %record;
	my @tmp;
	my (%per1, %per2);
	my @sta;
	my @rdiff;
	my @dirs;
	my @year_sta;
	my $i = 0;

	opendir ( FH, $cdir );
	@dirs = grep !/\./, readdir(FH);
	close(FH);
	@dirs = sort { $b <=> $a } @dirs;

#	foreach ( sort {$b <=> $a} keys %record ){
	foreach ( @dirs ){
		my @temp1;
		my @temp_s;
		my %per;
		eval{ @temp1 = @{ lock_retrieve ( "$cdir/$_/$yrec_data" ) } };
		eval{ %per  = %{ lock_retrieve ( "$cdir/$_/$ylev_data" ) } };
		push ( @{$temp2[0]}, @{$temp1[0]});
		push ( @{$temp2[1]}, @{$temp1[1]});
#		push ( @rdiff, @{$temp1[3]});
		push ( @rdiff, @{$per{sort2}});
		foreach $d ( keys %{$per{sort1}} ){
			$per1{$d}{win}  += $per{sort1}{$d}{win};
			$per1{$d}{lose} += $per{sort1}{$d}{lose};
			$per1{$d}{draw} += $per{sort1}{$d}{draw};
		}
		
		if ( $per{sta}{game} == 0 ){
			next;
		}
		
		$temp_s[0] = $_;
		$temp_s[1] = $per{sta}{tn};
		$temp_s[2] = $per{sta}{game};
		$temp_s[3] = $per{sta}{allp};
		$temp_s[4] = $per{sta}{newp};
		$temp_s[5] = $per{sta}{ave};
		$temp_s[6] = $per{sta}{sd};
		push (@year_sta, \@temp_s);
		
#		print "statistics display\n";
#		print join(' ',@temp_s),"\n";
	}

	lock_store ( \@year_sta, $sta_data );

	print "statistics 更新\n";



	@{$temp2[2][0]} = ( sort { $temp2[0][$b][4] <=> $temp2[0][$a][4] } (0 .. $#{$temp2[0]}) );
	@{$temp2[2][1]} = ( sort { $temp2[0][$a][4] <=> $temp2[0][$b][4] } (0 .. $#{$temp2[0]}) );
	@{$temp2[2][2]} = ( sort { $temp2[1][$b][5] <=> $temp2[1][$a][5] } (0 .. $#{$temp2[1]}) );

	foreach ( 0 .. 209 ) {
		push (@{$temp[0]}, \@{$temp2[0][$temp2[2][0][$_]]} );
		push (@{$temp[0]}, \@{$temp2[0][$temp2[2][1][$_]]} );
		push (@{$temp[1]}, \@{$temp2[1][$temp2[2][2][$_]]} );
	}

	@{$temp[2][0]} = ( sort { $temp[0][$b][4] <=> $temp[0][$a][4] } (0 .. $#{$temp[0]}) );
	@{$temp[2][1]} = ( sort { $temp[0][$a][4] <=> $temp[0][$b][4] } (0 .. $#{$temp[0]}) );
	@{$temp[2][2]} = ( sort { $temp[1][$b][5] <=> $temp[1][$a][5] } (0 .. $#{$temp[1]}) );

	lock_store ( \@temp, $rec_data );

	print "record 更新\n";


#	open(FH,"> $statistics");
	foreach ( sort {$a <=> $b} keys %per1 ){
		if ( $_ eq "-0" ){
			last;
		}
		my ($level, $total) = &cal_level($per1{$_}{win}, $per1{$_}{lose}, $per1{$_}{draw});
		my $ilevel = &cal_ilevel( $_*10 );

		my $str = sprintf ("%s ～ %s", $_*10, $_*10+10);

#		print FH sprintf("%s,%d,%d,%d,%d,%.3f,%.3f,\n", $str, $total, $per{$_}{win}, $per{$_}{lose}, $per{$_}{draw}, $level, $ilevel );
#		print FH sprintf("%s,%d,%d,%d,%d,%.3f,%.3f,\n", $str, $total, $per{$_}{win}, $per{$_}{lose}, $per{$_}{draw}, $level, $ilevel );
#		$ilevel = sprintf("%.3f", $ilevel);
		my @temp;

		$temp[0] = $str;
		$temp[1] = int($total);
		$temp[2] = int($per1{$_}{win});
		$temp[3] = int($per1{$_}{lose});
		$temp[4] = int($per1{$_}{draw});
		$temp[5] = sprintf("%.3f", $level);
		$temp[6] = sprintf("%.3f", $ilevel);

		push ( @{$sta[0]},\@temp );
	}

	@tmp = map {(split /,/)[0]} @rdiff;
	@rdiff = @rdiff[sort {$tmp[$a] <=> $tmp[$b]} 0 .. $#tmp];

	my $pre = 0;
	foreach (0 .. $#rdiff) {
		my $r = (split(/:/, $rdiff[$_]))[1];
		$per2{$r}++;
		if (($_+1) % 500 == 0 or $_ == @rdiff-1){
			my $now = (split(/:/, $rdiff[$_]))[0];
			my ($level, $total) = &cal_level($per2{win}, $per2{lose}, $per2{draw});
			my $str = sprintf ("%.2f ～ %.2f", $pre, $now);
			my $ilevel = &cal_ilevel( $pre );

#			print FH sprintf("%s,%d,%d,%d,%d,%.3f,%.3f,\n", $str, $total, $per2{1}, $per2{2}, $per2{3}, $level, $ilevel );
			my @temp;
			$temp[0] = $str;
			$temp[1] = int($total);
			$temp[2] = int($per2{win});
			$temp[3] = int($per2{lose});
			$temp[4] = int($per2{draw});
			$temp[5] = sprintf("%.3f", $level);
			$temp[6] = sprintf("%.3f", $ilevel);
			push ( @{$sta[1]},\@temp );
			%per2 = ();
		} elsif ( $_ % 500 == 0 ){
			my $now = (split(/:/, $rdiff[$_]))[0];
			$pre = $now;
		} 
	}

	lock_store(\@sta, $lev_data);

	print "level 更新\n";

}


sub text2hash{
#	my($data, $date)= @_;
	my $ref   = $_[0];
	my $ref2  = $_[1];
	my $tdata = $_[2];

	my $flag = 0;
	my ($player, $id);
	my ($slim_width, $cut_size);
	my ($games);
	my (%tg);
	my $o;
	my %sn;
	my %r;

#
# data structure of ref
# 0 : name scholar
# 1 : dan  scholar
# 2 : dis  scholar
# 3 : game array
## 4 : win  scholar
## 5 : lose scholar
## 6 : draw scholar
## 7 : high scholar
## 8 : ave  scholar
## 9 : prest  scholar
##10 : sufst  scholar
##11 : streak scholar

#data structure of %tg player
# -> abbr    : himself id
# -> result  : result of each game
# -> id      : opponent of each player

	$r{"○"} = 1;
	$r{"×"} = 2;
	$r{"△"} = 3;

	my $period = 0;

	$o = 0; # identification number
	foreach (split(/\n/, $tdata)){
		if ( $_ =~ s/^\s*\d+\. ($sjis)\s+($sjis)\s+($sjis)// ){
			$player = "$1 $2";
			if ( exists($rep{$player}) ){
				$player = $rep{$player};
			}
			if ( exists($rname{$player}) ){
				$player = $rname{$player};
			}
			$id = $3;
			push(@{$sn{$id}}, $player);
			$$ref2{$player} = $o;
			$$ref[0][$o]    = $player;
			$o++;
			if ( length($id) > $period ){
				$period = length($id);
			}
		}
	}

	if ( $period == 4 ){
		$period = 6;
	} else {
		$period++;
	}

	foreach (split(/\n/, $tdata)){
		
		$slim_width = length( $_ );
		if ( $_ =~ s/^\s*\d+\. ($sjis)\s+($sjis)\s+($sjis) // ){
#		if ( $_ =~ s/\d+\. ([^\s　]+) ([^\s　]+)[\s]*(\S+)// ){
			$player = "$1 $2";
			
			if ( exists($rep{$player}) ){
				$player = $rep{$player};
			}
			if ( exists($rname{$player}) ){
				$player = $rname{$player};
			}

#			print "player $1 $2 $3 $4 $5 $6\n";
			$tg{$player}{abbr} = $3; #abbreviation

			$cut_size = $slim_width - length ($_) ;
			$_ =~ s/Δ/△/g;


#			print "id: $player $_ \n";
			my $i=1;
			while($_ =~ s/^(\s*)(○|×|△)\s?[+-]?\s{0,2}[\d\.]+//){
				my $space  = $1;
				my $result = $2;
				while ( $space =~ s/\s{$period}// ){
					$i++;
				}

				$tg{$player}{result}{$i} = $r{$result}; # assign result
#				print "$result $i $_ \n";
				$i++;
			}
			$flag = 1;

###			$_ =~ /(\d+勝\s*\d+敗\s*\d+分)/;
###			$$ref[3][$sn{$id}] = $1;

		} elsif ( $flag == 1 ){
			$_ =~ s/^(.{$cut_size}($sjis)?)//;
#			print "$_\n";
			my $temp = $1;
#			print "t $temp  $1 $2\n";
			my( $dan, $dist );
#			@test = split /\s+/, $temp;

			if ( $temp =~ s/($sjis)\s?$// ){
				$dan = $1;
			} else {
#				$dan = "無級";
				$dan = "";
			}
#			print "t $temp\n";
			if ( $temp =~ /($sjis)/ ){
				$dist = $1;
				$dist =~ s/\-//;
				$dist =~ s/・//;
				$dist =~ s/府//;
				$dist =~ s/県//;
				$dist =~ s/東京都/東京/;
				$dist =~ s/(青森|岩手|宮城|秋田|山形|福島)/東北/;
				$dist =~ s/(栃木|群馬|埼玉)/北関東/;
				$dist =~ s/千葉/東関東/;
				$dist =~ s/山梨/神奈川/;
				$dist =~ s/静岡/東海/;
				$dist =~ s/(長野|岐阜|愛知|三重)/中部/;
				$dist =~ s/^(三重|滋賀|京都|大阪|奈良|和歌山|富山|石川|福井|近畿|北陸)$/近畿北陸/;
				$dist =~ s/^(鳥取|島根|岡山|広島|山口|徳島|香川|愛媛|高知|中国|四国)$/中四国/;
				$dist =~ s/(福岡|佐賀|長崎|熊本|大分|宮崎|鹿児島|沖縄)/九州/;
			} else {
#				$dist = "不明";
				$dist = "";
			}

			$$ref[1][$$ref2{$player}] = $dan;
			$$ref[2][$$ref2{$player}] = $dist;

			my $i=1;
			while($_ =~ s/(\s*)($sjis)//){
				my $space  = $1;
				my $id2 = $2;
				
#				print "$_ $player ";
				while ( $space =~ s/\s{$period}// ){
					$i++;
				}

				if ($id2 =~ /不戦/ ){
					$i++;
					next;
				}

				$tg{$player}{id}{$i} = $id2;

				$i++;
			}
			$flag = 0;
		}
	}


	foreach $player ( keys %tg ){
		foreach $i ( sort keys %{$tg{$player}{result}}){
			foreach $player2 ( @{$sn{$tg{$player}{id}{$i}}} ) {
				if ( $tg{$player}{abbr} eq $tg{$player2}{id}{$i} ){
					$$ref[3][$i][$$ref2{$player}][0] = $$ref2{$player2};
					$$ref[3][$i][$$ref2{$player}][1] = $tg{$player}{result}{$i};
				}
			}
		}
	}


#	print "slim 生成 $n\n";

}

sub up_hash {

	local $ref   = $_[0];

#	$r{"○"} = 1;
#	$r{"×"} = 2;
#	$r{"△"} = 3;

	foreach $n (0 .. $#{$$ref[0]}){
		$name = $$ref[0][$n];
		if ($rate{$name}{now} == 0){
			if ( $base{$name}{now} ){
				$rate{$name}{now} = $base{$name}{now};
			} elsif ( $rate{$name}{dan} ){
#				$rate{$name}{now} = $srate{$rate{$name}{dan}};
				$rate{$name}{now} = 900;
			} else {
				$rate{$name}{now} = 900;
			}
		}
#		$rate{$name}{before} = $rate{$name}{now};
#		$rate{$name}{after}  = $rate{$name}{now};
#		$rate{$name}{date}   = $date;
#		$rate{$name}{dan}    = $$ref[1][$n];
#		$rate{$name}{dist}   = $$ref[2][$n];
		$$ref[3][0][$n][2] = $rate{$name}{now};
#		$$ref[8][$n] = 0;
#		$$ref[9][$n] = 0;
#		print "$name $rate{$name}{now}  $$ref[3][0][$n][2]\n";
	}

	foreach $l ( 1 .. $#{$$ref[3]} ){
#		foreach $m1 ( 0 .. $#{$$ref[3][$l]} ){
		foreach $m1 ( 0 .. $#{$$ref[0]} ){
			my $m2 = $$ref[3][$l][$m1][0];

#			printf ("%2d %2s %-14s %10.4f %-14s %10.4f\n", 
#					$l, $$ref[3][$l][$m1][1], $$ref[0][$m1], $$ref[3][$l-1][$m1][2], $$ref[0][$m2], $$ref[3][$l-1][$m2][2]);

#			if ( $$ref[3][$l][$m1][2] ){ next; }

#			if ( !$$ref[3][$l][$m1][1] or $$ref[3][$l][$m1][1] eq "×" ){ 
			if ( !$$ref[3][$l][$m1][1] ){ 
				$$ref[3][$l][$m1][2] = $$ref[3][$l-1][$m1][2];
#				print "husen $$ref[0][$m1] $$ref[3][$l][$m1][1] $l $$ref[3][$l-1][$m1][2] $$ref[3][$l-1][$m2][2]\n";
				next; 
			}
			if ( $$ref[3][$l][$m1][1] == 2 ){ next; } 

			my $dr = $$ref[3][$l-1][$m1][2] - $$ref[3][$l-1][$m2][2];
			my $iad = (32+33*(($dr/600)**2))/(1+2**($dr/100));

			if ($$ref[3][$l][$m1][1] == 3){
				my $iad2;
				$dr   = -$dr;
				$iad2 = (32+33*(($dr/600)**2))/(1+2**($dr/100));
				$iad  = ($iad-$iad2)/2;
			}

			$$ref[3][$l][$m1][2] = $$ref[3][$l-1][$m1][2] + $iad;
			$$ref[3][$l][$m2][2] = $$ref[3][$l-1][$m2][2] - $iad;

#			if ( $$ref[3][$l][$m1][2] > $$ref[8][$m1] ){
#				$$ref[8][$m1] = $$ref[3][$l][$m1][2];
#			}

#			if ( $$ref[3][$l][$m2][2] > $$ref[8][$m2] ){
#				$$ref[8][$m2] = $$ref[3][$l][$m2][2];
#			}

#			$$ref[9][$m1] += $$ref[3][$l][$m1][2];
#			$$ref[9][$m2] += $$ref[3][$l][$m2][2];

		}
	}

}

sub slim2rate {
	my $ref  = $_[0];
	my $date = $_[1];

	my $m = @{$$ref[3]} - 1;

	foreach $n (0 .. $#{$$ref[0]}){
		my $name = $$ref[0][$n];
		$rate{$name}{now} = $$ref[3][$m][$n][2];
#		printf ("check!! %s %-14s %2s %10.4f %10.4f\n", $date, $name, $m, $$ref[3][0][$n][2], $$ref[3][$m][$n][2], );
		push ( @{$rate{$name}{date}}, $date );
	}
}

sub sresult{

	my ($ref1, $ref2, $data) = @_;
	@lines = split( /\n/, $data );
	my $rdata;

	foreach (@lines){
		$_ =~ s/\n$//;
#		print $_;
		$rdata .= $_;

		if ( $_ =~ s/\d+\. ($sjis)\s+($sjis)\s+($sjis)// ){
#		if ( $_ =~ s/\d+\. ([^\s　]+) ([^\s　]+)[\s　]*(\S+)// ){
			my $player = "$1 $2";
			if ( exists($rep{$player}) ){
				$player = $rep{$player};
			}
			if ( exists($rname{$player}) ){
				$player = $rname{$player};
			}

			my $n = $$ref2{$player};
			my $m = @{$$ref1[3]} - 1;

			$rdata .= sprintf ("  %5d -> %4d", $$ref1[3][0][$n][2], $$ref1[3][$m][$n][2] ) ;

		}
#		print "\n";
		$rdata .= "\n";
	}
	
	return $rdata;
}


sub sresult2 {

	my ($ref1, $ref2, $data) = @_;
	@lines = split( /\n/, $data );
	my $rdata = <<"_HTML_";
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Cache-Control" content="no-cache">
<meta name="robots" content="noindex,nofollow">
<meta name="robot"  content="noindex,nofollow">
</head>
<body>
<pre>
_HTML_

	foreach (@lines){
		$_ =~ s/\n$//;
#		print $_;

		if ( $_ =~ s/^(\s*\d+\.)\s+($sjis)\s+($sjis)// ){
			my $space = $1;
			my $player = "$2 $3";
			my $dplayer;
			
			if ( exists($rep{$player}) ){
				$player = $rep{$player};
			}
			$dplayer = $player;
			if ( exists($rname{$player}) ){
				$player = $rname{$player};
			}

			my $n = $$ref2{$player};
			my $m = @{$$ref1[3]} - 1;

			my $enc = $dplayer;
			$enc =~ s/(.)/sprintf("%%%02X", unpack("C", $1))/eg;
			$rdata .= "$space <a href=\"?pd=3&id=$enc\">$dplayer</a>";

			$rdata .= $_;
			$rdata .= sprintf ("  %5d -> %4d", $$ref1[3][0][$n][2], $$ref1[3][$m][$n][2] ) ;

		} else {
			$rdata .= $_;
		}
		
#		print "\n";
		$rdata .= "\n";
	}
	
	$rdata .= <<"_HTML_";
</pre>
</body>
</html>
_HTML_

	return $rdata;
}
 