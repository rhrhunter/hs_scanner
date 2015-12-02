Usage:
* ./hs_scanner

Set the window aside and then start up hearthstone (in windowed mode) and play. 
The tracker will log the game in a file called hs_game.log in the current working directory. 

It will also display the following in real time:

* Your Drawn Cards
* Enemy Cards Played
* Enemy Secrets

It will keep track of enemy secrets played as well as let you know when they get revealed.

It also keeps track of your matchups and stores all your records in a file called hs_records.log in the current working directory.

The records that are kept include:
* Win/Loss Record between your hero and the enemy hero.
* Win/Loss Record overall between you and the opponent with your selected hero.
* Win/Loss Record overall with your selected hero.

![Alt text](hs_scanner.png?raw=true "hs_scanner")