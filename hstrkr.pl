#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Cwd;

my $CWD = getcwd();

sub enable_logging {
    `mkdir -p ~/Library/Preferences/Blizzard/Hearthstone/`;
    `echo "[Zone]" > ~/Library/Preferences/Blizzard/Hearthstone/log.config`;
    `echo "LogLevel=1" >> ~/Library/Preferences/Blizzard/Hearthstone/log.config`;
    `echo "FilePrinting=false" >> ~/Library/Preferences/Blizzard/Hearthstone/log.config`;
    `echo "ConsolePrinting=true" >> ~/Library/Preferences/Blizzard/Hearthstone/log.config`;
    `echo "ScreenPrinting=true" >> ~/Library/Preferences/Blizzard/Hearthstone/log.config`;
}

my ($player_log) = `ls ~/Library/Logs/Unity/Player.log`;
chomp($player_log);

sub init_player_log {
    `mkdir -p ~/Library/Logs/Unity`;
    `touch ~/Library/Logs/Unity/Player.log`;
    `echo "" > ~/Library/Logs/Unity/Player.log`;
}

sub update_results {
    my ($drawn_cards, $enemy_secrets, $enemy_cards) = @_;

    system("touch $CWD/hs_hand.log");
    system("rm $CWD/hs_hand.log");

    open (FH2, ">", "$CWD/hs_hand.log");
    my $h = {};
    $h->{"Drawn Cards"} = $drawn_cards;
    $h->{"Enemy Cards"} = $enemy_cards;
    $h->{"Enemy Secrets"} = $enemy_secrets;
    print FH2 Dumper($h);
    close(FH2);
}

sub msg {
    my ($msg) = @_;
    print $msg . "\n";

    system("touch $CWD/hs_game.log");
    system("rm $CWD/hs_game.log");

    open (FH3, ">>", "$CWD/hs_game.log");
    print FH3 $msg . "\n";
    close(FH3);
}

sub scan_player_log {    
    msg("Opening File: $player_log");
    open(FH1, "<", "$player_log") or die("Could not open file: $player_log");
    
    my $drawn_cards   = {};
    my $enemy_secrets = {};
    my $enemy_cards   = {};
    my $current_enemy;
    my $friendly_hero;
    my $friendly_player_id = -1;

    msg("Clearing out results file");
    update_results($drawn_cards, $enemy_secrets, $enemy_cards);

    while (1) {
	while (my $line = <FH1>) {
	    chomp($line);
	    update_results($drawn_cards, $enemy_secrets, $enemy_cards);

	    if ($line =~ /TRANSITIONING card \[(.+?)\] to (FRIENDLY|OPPOSING) (PLAY|GRAVEYARD|PLAY|SECRET|HAND|DECK)/i or 
		$line =~ /TRANSITIONING card \[(.+)\] to\s*$/) {
		
		my $card_details = $1;
		my $player = $2;
		my $type = $3;
		my $is_hero = 0;
		if ($line =~ /\(Hero\)/i) {
		    $is_hero = 1;
		}
		my $is_hero_power = 0;
		if ($line =~ /\(Hero Power\)/i) {
		    $is_hero_power = 1;
		}

		# skip hero power lines
		next if ($is_hero_power);

		# figure out the card name and ID
		my $card_name;
		if ($card_details =~ /name=(.+?)\s\S+=/i) {
		    $card_name = $1;
		}
		my $card_id;
		if ($card_details =~ /id=(\d+)/i) {
		    $card_id = $1;
		}
		my $card_uuid;
		if ($card_details =~ /cardId=(\S+)/i) {
		    $card_uuid = $1;
		}
		my $card_type = "";
		if ($card_details =~ /type=(\S+)/) {
		    $card_type = $1;
		}
		my $player_id;
		if ($card_details =~ /player=(\d+)/i) {
		    $player_id = $1;
		}

		# this means we are starting a new game
		if ($is_hero and $player and $player eq "FRIENDLY" and $player_id) {
		    # identify the friendly player id
		    $friendly_player_id = $player_id;
		    $friendly_hero = $card_name;
		    msg("Resetting data structures for new game (friendly player id: $friendly_player_id)");
		    msg("Playing as: $friendly_hero");
		    		    
		    # new game
		    $drawn_cards   = {};
		    $enemy_secrets = {};
		    $enemy_cards   = {};
		    update_results($drawn_cards, $enemy_secrets, $enemy_cards);    
		    next;
		}

		# figure out who we are playing against
		if ($is_hero and $player and $player eq "OPPOSING") {
		    $current_enemy = $card_name;
		    msg("Playing against: $current_enemy");
		    next;
		}

		# sometimes it loses track of who the friendly player is
		if ($player and $player eq "FRIENDLY" and $player_id) {
		    $friendly_player_id = $player_id;
		}

		my $zone;
		if ($card_details =~ /zone=(\S+)/i) {
		    $zone = $1;
		}
		if ($zone and $zone eq 'SETASIDE') {
		    # this is the result of a joust, ignore it
		    next;
		}
		if ($zone and $zone eq 'DECK' and !$type) {
		    # these are cards that come from the deck whenever there is a joust
		    next;
		}

		# keep track of spells
		if (!$player and !$type) {
		    if ($friendly_player_id ne $player_id) {
			msg("Enemy Spell: $card_name");
			$enemy_cards->{$card_name}++;
		    } else {
			msg("Friendly Spell: $card_name");
		    }
		    next;
		}
		
		# ignore cards drawn by enemy
		next if ($player eq "OPPOSING" and $type =~ /HAND|DECK/);

		# see if its a card we mulliganned
		if ($card_type ne 'INVALID' and $player eq "FRIENDLY" and $type eq "DECK") {
		    $drawn_cards->{$card_name}--;
		    if ($drawn_cards->{$card_name} <= 0) {
			msg("Mulliganned: $card_name");
			delete($drawn_cards->{$card_name});
			next;
		    }
		}	       
		
		# see if the opponent played a secret
		if ($player eq "OPPOSING" and $type eq "SECRET") {
		    msg("Enemy secret played");
		    $enemy_secrets->{$card_id} = undef;
		    next;
		}
		
		# if the an enemy card went to the graveyard, see if it
		# was because a secret was revealed
		if ($player eq "OPPOSING" and $type eq "GRAVEYARD") {
		    if (exists $enemy_secrets->{$card_id}) {
			msg("Enemy secret revealed: $card_name");
			$enemy_secrets->{$card_id} = $card_name;
			next;
		    }
		}
		
		# keep track of cards we've drawn
		if ($player eq "FRIENDLY" and $type eq "HAND") {
		    msg("Drew: $card_name");
		    $drawn_cards->{$card_name}++;
		    next;
		} 

		# keep track of minions we played
		if ($player eq "FRIENDLY" and $type eq "PLAY") {
		    msg("Friendly minion: $card_name");
		    next;
		}
		
		# keep track of minions the enemy has played
		if (not $is_hero and $player eq "OPPOSING" and $type =~ /PLAY/)  {
		    msg("Enemy minion: $card_name");
		    $enemy_cards->{$card_name}++;
		    next;
		}
	    }
	}
	# nothing new sleep a bit
	sleep 2;
    }
}

# main

enable_logging();
init_player_log();
scan_player_log();
