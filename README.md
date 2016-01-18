[![Build Status](https://travis-ci.org/rhrhunter/hs_scanner.svg?branch=master)](https://travis-ci.org/rhrhunter/hs_scanner)

Usage:
* ./hs_scanner [logging=0|1]

Set the window aside and then start up hearthstone (in windowed mode) and play.
If logging is enabled, the tracker will log the game in a file called hs_game.log
in the current working directory.

For normal play, It will display the following in real time:

* Your Drawn Cards
* Enemy Cards Played
* Enemy Secrets

For arena play, it will track the progress of your arena deck in real time:

* The current arena deck
* The current arena record
* Your average win rate across all your completed arenas
* The cards in your arena deck that have not been drawn yet
* Enemy Secrets

It will keep track of enemy secrets played as well as let you know when they get revealed.

It also keeps track of your matchups (arena and play mode) and stores all
your records in a file called hs_records.log in the current working directory.

The records that are kept include:
* Win/Loss Record between your hero and the enemy hero.
* Win/Loss Record overall between you and the opponent with your selected hero.
* Win/Loss Record overall with your selected hero.
* All arena runs.

![Alt text](hs_scanner.png?raw=true "hs_scanner")
