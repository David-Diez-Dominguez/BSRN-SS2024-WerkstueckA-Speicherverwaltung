# BSRN-SS2024-WerkstueckA-Speicherverwaltung

Vor dem Starten muss sichergestellt werden, ob bc installiert ist.
Dazu muss der Befehl sudo apt-get install bc ausgeführt werden.

Um die Simulation zu starten muss dem Argument Speicherverwaltung, eines der nachfolgenden Optionen übergeben werden.
Entsprechend steht unten exemplarisch ein Befehle für jede Option zu Verfügung.

Wenn dynamic als Speicherverwaltung gewählt wurde, muss beachtet werden, dass das zusätzliche Argument Konzept angegeben werden muss,
wo zwischen first, next und best unterschieden werden kann.


-static 
./simulation.sh -speicherverwaltung static -prozessdatei input.txt -logdatei logfile.txt

-dynamic
./simulation.sh -speicherverwaltung dynamic -konzept first -prozessdatei input.txt -logdatei logfile.txt

-buddy 
./simulation.sh -speicherverwaltung buddy -prozessdatei input.txt -logdatei logfile.txt

Punkte 59/60

