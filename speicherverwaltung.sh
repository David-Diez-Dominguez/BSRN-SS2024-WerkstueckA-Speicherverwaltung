#!/bin/bash
#Die Best Fit Methode sucht nach der kleinsten Lücke im Speicherplatz um einen neune Prozess hinzuzufügen
bestFit(){
    start=0
    ende=0
    #alle potentiellen Lücken "options" werden in diesem Array geseichert
    fitOptions=()
    #Mit dem zähler wird die anzahl der hintereinander feien Positionen gesucht
    leerzaehler=0
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
        #Immer wenn eine position frei ist, wird der zähler um 1 inkrementiert
            if [[ -z "${matrix[$i,$j]}" ]]; then
              ((leerzaehler++))
            fi
            #Wenn unsere for-Schleife entweder einmal ganz duchgelaufen ist, oder auf eine befüllte Stelle im Speicher trifft...
            if [[ $i -eq $matrixLaenge || -n "${matrix[$i,$j]}" ]]; then
            #...dann schauen wir ob unserer Zähler (der hintereinander leeren Positionen) >=  unserer Prozessgröße ist 
            #=> wir also eine frei Lücke gefunden haben
            #wenn das der Fall sein sollte, ermitteln wir das Ende und den Start dieser Option
              if [[ $leerzaehler -ge $1 ]]; then
                ende=$((i))
                start=$((i - leerzaehler + 1))
                #wenn eine Lücke gefunden wird die sich zwischen zwei Prozessen befindet, muss der Start und das Ende anders berechnet werden
                 if [[ $i -lt $matrixLaenge ]];then
                ende=$((i - 1))
                start=$((i - leerzaehler))
                fi
              #Anschließend wird die gefundene Lücke in den fitOptions Array hinzugefügt
                fitOptions+=("$start","$ende")
              fi
              #Wenn wir zwischendurch eine belegte Position gefuden haben, setzen wir den Zähler wieder auf 0
                leerzaehler=0
            fi
        done
    done

    #Wenn keine Lücke gefunden wird, wird die Fehlermeldung ausgegeben
    if [ ${#fitOptions[@]} -eq 0 ]; then
        echo "Es wurde keine freie Lücke für den Prozess gefunden"
        return
    fi

    start=0
    ende=0   

    #Am Ende durchlaufen wir alle freien Lücken um die kleinste zu finden, in der unsere Prozess reinpasst
    for option in "${fitOptions[@]}"; do
        anfangArray=$(echo "$option" | cut -d',' -f1)
        endeArray=$(echo "$option" | cut -d',' -f2)
        #hier ermitteln wir die größe der Lücke
        size=$((endeArray - anfangArray + 1))

        #Um in diese if bedingung die kleinste Lücke zu finden
        if [[ $size -le $matrixLaenge ]]; then
            start=$anfangArray
            ende=$((start + $1 - 1))
            matrixLaenge=$size
        fi
    done
        #Am ende geben wir den Start und das Ende der add Methode zurück
     echo "$start $ende" 
}

#Die First und Next Fit Methode sucht den passende Start und Ende um einen Prozess hinzuzufügen
firstNextFit(){
    #Bei First Fit starten wir immer ab 1, also ab dem Anfang vom Array
    startPunkt=1
    prozessgroesse=$1
    #Bei Next Fit ist unsere Stertpunkte der zuletzt verwendetes Ende + 1 
    if [ "$konzept" == "next" ];then
        startPunkt=$2
    fi
    #Anschließend definieren wir einen Counter, der so Groß ist wie die Prozessgröße selbst
    freieStelleCounter=$1;
    start=0
    ende=0
    #Hier durchlaufen wei die schleife ab dem Startpunnkt bis zum Ende
    for ((i=$startPunkt; i<=matrixLaenge; i++)); do
    #immer wenn wir eine freie Position gefunden haben, dekrementieren wir den Zähler um 1
        if [[ -z "${matrix[$i,2]}"  && $freieStelleCounter -gt 0 ]]; then
           ((freieStelleCounter -= 1))
        fi
        #wird einee bereits belegte Position gefunden müssen wir den Zähler wieder auf den ursprünglichen Wert setzen
        if [[ -n "${matrix[$i,2]}"  ]]; then
            freieStelleCounter=$1
        fi
        #Ist der counter dann gleich 0, also es wurde eine freie Stelle gefunden wo der Prozess rein passt,
        #ermittel wir den Start und das Ende
        if [[ $freieStelleCounter -eq 0  ]]; then 
            ende=$i
            start=$((ende - prozessgroesse + 1))
            echo "$start $ende"
            break 3
        fi
        #Wird beim Next fit die Schliefe einmal durchalufen und keine passende freie Stelle gefunen, so setzten wir den Startpukt auf 1
        #und lassed  die Schleife durchlaufen,bis sie den alten Startwert (vom next Fit) ereicht hat
        if [[ $freieStelleCounter -gt 0 && i -ge $matrixLaenge  ]]; then
            startPunkt=1
            matrixLaenge=$2
            freieStelleCounter=$1
            i=$startPunkt
        fi
    done
}

#Diese Methode fügt Prozesse für alle 3 dynamischen Parttionierungskonzepte auf Basis deren Start und Ende Wert hinzu
addProzessDynamic() {
    pgroesse=$(echo "$1" | cut -d',' -f2 | tr -dc '0-9' )
    prozessName=$(echo "$1" | cut -d',' -f1)
    #Je nach Konzeptarte rufen wir die dazugehörige Methode auf
    if [[ "$konzept" == "first" || "$konzept" == "next" ]]; then
    startEnde=$(firstNextFit $pgroesse $lastindex)
    fi
    if [[ "$konzept" == "best" ]]; then
    startEnde=$(bestFit $pgroesse)
    fi
    #Mit dieser darunter stehenden Zeile lesen wir das Start und das End unseres Rückhabewertes
    read -r start ende <<< "$startEnde"
    #Für die Next Fit Methode müssen wir die letzte benutzte Position +1 berechenen, um den neuen Startwert zu haben
    lastindex=$((ende + 1))
    #Die letzeIndexFragmentierung hilft uns bei der Exteren Fragmentierung auch nur den Speicherplatz zu werten,
    # der auch schon einmla verwendet wurde
    if [[ $lastindex  -gt $letzeIndexFragmentierung ]];then
    letzeIndexFragmentierung=$lastindex
    fi
    #Hier werden die Prozess in die Matrix hinzugefügt
    for ((i=start; i<=ende; i++)); do
                matrix[$i,2]=$prozessName
    done
     if [[ $start -gt 0 ]]; then
    message="Der Prozess $prozessName wurde erfolgreich hinzugefügt"
            echo $message
            log "$message"
    fi

}

#Diese Methode fügh Prozesses für die statische Partitionierung hinzu
addProzessStatic() {
    platzgefunden=0
    prozessName=$(echo "$1" | cut -d',' -f1)
    pgroesse=$(echo "$1" | cut -d',' -f2 | tr -dc '0-9' )
    #Es wir die Matrix durchlaufen und überprüft, dass noch keine Partition gefunden wurde und unsere Prozessgröße kleiner als die Partition ist
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
            if [[ -z "${matrix[$i,$j]}" && $platzgefunden -eq 0 && $pgroesse -le $partition ]]; then
            # Wurde eine Freie Partition gefunden, fügen wir den Prozessname und seine Größe an die freie Stelle hinzu
                matrix[$i,$j]=$1
                platzgefunden=1
                #und setzen das platzgefunden Flag auf 1
                message="Der Prozess $prozessName wurde erfolgreich hinzugefügt"
                echo $message
                log $message
            fi
            #Ist die Prozessgröße > als die Partition, wird die entsprechende Fehlermeldung ausgegeben
            if [[ $pgroesse -gt $partition ]]; then
                message="$prozessName konnte nicht hinzugefügt werden. Der Prozess mit der Größe $pgroesse MB ist zu groß für die Patritionsgröße ($partition MB)."
                log "$message"
                echo $message
                return
            fi
        done
    done
    #Ebennso erfolgt eine Fehlermeldung, wenn alle Partitionen bereits belegt sind
        if [[ $platzgefunden -eq 0 ]]; then
               message="$prozessName konnte nicht hinzugefügt werden. Alle Partitionen sind bereits belegt."
                log "$message"
                echo $message
        fi
}

#Die Remove Prozess Methode entfernt die Prozesses auf Grundlage der Prozessnamen und gilt sowohl für die statische als auch dynamishe Partitionierung
removeProzess() {
    deleted=false
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
            prozess="${matrix[$i,$j]}"
            matrixProzess=$(echo "$prozess" | cut -d',' -f1 )
            #wird eine Prozess in der Matrix mit dem selben Namen gefunden, so wir er aus der Matrix entfernt
            if [[ "$matrixProzess" == "$1" ]]; then
                matrix[$i,$j]=""
                deleted=true
            fi
        done
    done
    #Anschließend erfolgt eine Fehlermeldung bei erfolgreichen bzw. fehlgeschlagenen Löschen 
    if [[ "$deleted" == false ]]; then
        message="Prozess $1 wurde nicht gefunden."
        echo $message
        log "$message"
        else
        message="Prozess $1 wurde erfolgreich entfernt."
        echo $message
        log "$message"
    fi
}

#Wie der Metodenname schon errät, wird hier die eindeutigkeit des Prozessnamen überprüft
checkIfProzessNameIsUnique() {
     prozessName=$(echo "$1" | cut -d',' -f1)
    log "Überprüfe ob der Prozessname $prozessName eindeutig ist "
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
             prozessInMatrix="${matrix[$i,$j]}"
             prozessNameInMatrix=$(echo "$prozessInMatrix" | cut -d',' -f1)
             #Wenn der übergebene Prozessname bereits in der Matrix gefunden wird,...
            if [[ "$prozessName" == "$prozessNameInMatrix" ]]; then
            #...so wird der Benutzer aufgefordert einen neune Namen zu übergeben...
             read -p "Der Prozessname $prozessName existiert bereits. Bitte gib einen neuen Prozessnamen ein: " neuerProzessName </dev/tty
             log "Der Prozess mit dem namen $prozessName existiert bereits und wurde zu $neuerProzessName geändert"
             #...und erneut überprüft, ob dieser Prozessname eindeutig ist
             neuerName=$(checkIfProzessNameIsUnique "$neuerProzessName")
              #Der neue Name wird dann zurückgegeben
            echo "$neuerName"
                return
            fi
        done
    done
    log "Der Prozessname $prozessName ist eindeutig."
     # Wenn kein doppelter Name gefunden wurde, wird der ursprüngliche Namen zurückgegeben
    echo "$prozessName"
}

#Mit Hilfe einer for-Schelife wird die Matrix ausgegeben
ausgabe(){
for ((i=1; i<=matrixLaenge; i++)); do
    for ((j=1; j<=2; j++)); do
        echo -n "${matrix[$i,$j]}"
    done
    echo
done
}

#In dieser Methode wird der zu teilende Buddy geteilt
teileBuddy(){
    #als erstes speichern wir den Buddy der übergeben wurde und cutten den parentcontainerindex, sowie die buddygröße
    oldBuddy=$1
    parentContainerIndex=$(echo "$oldBuddy" | cut -d',' -f2)
    buddygroesse=$(echo "$oldBuddy" | cut -d',' -f3)
    
    #anschließend ermitteln wir mithilfe der getIndex Methode den INdex an dem der übergebende Buddy gespeichert ist
    oldBuddyIndex=$(getIndex $oldBuddy)
    #dieser wird dann aus dem Buddies Array entfernt
    unsetBuddy $oldBuddyIndex
    
    #Im Anschluss ermitteln wir die neue Größe der gesplatenen Buddies...
    neueGroesse=$((buddygroesse / 2))
    #...zählen den buddyindex jewils 1 mal für jeden neun Buddy
    #Der buddyPairIndex wird nur 1 mla hochgezählt, weil die buddies die zusammengehören somit bestimmt werden können
    ((buddyIndex++))
    ((buddyPairIndex++))
    buddies+=("$buddyIndex,$buddyPairIndex,$neueGroesse,0,$parentContainerIndex")
    ((buddyIndex++))
    buddies+=("$buddyIndex,$buddyPairIndex,$neueGroesse,0,$parentContainerIndex")
    
    #Am Ende mappen wir den neuen buddyPairIndex mit dem dazugehörigen parentContainerIndex um beim späteren Zusammenfügen die Buddys ihreen alten buddyPairIndex erhalten.
    parents+=($buddyPairIndex,$parentContainerIndex)
    
    #Nach dem Teilen wir wieder überprüft ob es jetzt einen freien Buuddy gibt der groß genug für den Prozess ist
    sucheFreienBuddy $2
}

#Nachdem ein Buddy wieder zusammengefügt wurde muss die Refferenz von zusammngefügten buddyPairIndex zu seinem parentContainerIndex gelöscht werden
unsetParent(){
    for parent in "${!parents[@]}"; do
        removeParentIndex=$(echo "$parent" | cut -d',' -f1)
        #Wenn der übergebende BuddyPairIndex des gespaltenen Buddys im Array gefunden wird, dann soller entfernt werden
        if [ "$removeParentIndex" == "$1" ]; then
            unset "parents[$parent]"
            parents=("${parents[@]}")
        fi
    done
}

#Hier wird der alte parentContainerIndex vom wieder zusaammengefügten Parent gesucht  
getOldParentByParentIndex(){
    for p in "${parents[@]}"; do
        parentIndex=$(echo "$p" | cut -d',' -f1)
        if [ "$parentIndex" == "$1" ]; then
            oldParentIndex=$(echo "$p" | cut -d',' -f2)
        fi
    done
    echo $oldParentIndex
    
}

#Sind 2 Buddies der sleben gr0e und mit dem selben buddyPairIndex nicht belegt, sow werden diese wieder zum ursprüglichen Parent zusammengefügt
buddiesZusammenfügen(){
    #Wird durchlaufen den Buddies Array 2 mal um die Buddies innerhalb des Arrays zu vergleicehn
    for buddy in "${buddies[@]}"; do
        buddyId=$(echo "$buddy" | cut -d',' -f1)
        buddyPairIndex=$(echo "$buddy" | cut -d',' -f2)
        buddygroesse=$(echo "$buddy" | cut -d',' -f3)
        buddygroesse=$((buddygroesse * 2))
        belegt=$(echo "$buddy" | cut -d',' -f4)
        parentIndex=$(echo "$buddy" | cut -d',' -f5)
        if [ $belegt -eq 0 ];then
            for comparedBuddy in "${buddies[@]}"; do
                comparedBuddyIndex=$(echo "$comparedBuddy" | cut -d',' -f1)
                comparedBuddyPairIndex=$(echo "$comparedBuddy" | cut -d',' -f2)
                comparedBelegt=$(echo "$comparedBuddy" | cut -d',' -f4)
                #Wenn beide Buddies des selben Pairs frei sind und es sich dabei nicht 2 mla unm den selben Budyy handelt, werden sie wieder zusammengeführ  
                if [[ $comparedBelegt -eq 0 && $buddyId -ne $comparedBuddyIndex
                    && $buddyPairIndex -eq $comparedBuddyPairIndex ]];then
                    
                    #Dabei sucht man den ParentIndex vom parent
                    oldparent=$(getOldParentByParentIndex $parentIndex)
                    
                    #Anschließende löscht man cie alte Refferenz vom zusammngefügten buddyPairIndex zu seinem parentContainerIndex 
                    unsetParent $buddyPairIndex                    
                    
                    #Es wird zunächst der zusammengeführte Buddy wieder dem Array hinzugefügt...
                    buddies+=("$buddyIndex,$parentIndex,$buddygroesse,0,$oldparent")
                    firstBuddyArrayIndex=$(getIndex $buddy)
                    #...und die gespaltenent buddies die zusammengeführt wurden, entfernt 
                    unsetBuddy $firstBuddyArrayIndex
                    secondBuddyArrayIndex=$(getIndex $comparedBuddy)
                    unsetBuddy $secondBuddyArrayIndex

                    #Gibt den zusammnegeführent Buddy zurück
                    arrayId=$(getArrayIndexByyBuddyId $buddyIndex)
                    newOldBuddy=${buddies[$arrayId]}
                    
                    log "$buddy wurde mit $comparedBuddy zu $newOldBuddy zusammengelegt"
                    buddiesZusammenfügen
                    break 4
                    
                fi
            done
        fi
    done
}

#Gibt den Array Index für die BuddyId zurück
getArrayIndexByyBuddyId(){
    buddyId=$1
    index=0
    counter=-1
    for bud in "${buddies[@]}"; do
        ((counter++))
        buddyIndex=$(echo "$bud" | cut -d',' -f1)
        if [[ $buddyIndex -eq $buddyId ]]; then
            index=$counter
            break 2
        fi
    done
    echo $counter
}

#Mithilfe des Prozessnamen wird der Prozess gelöscht und frei Buddies werden wirder zusammengefügt
removeProzessBuddy(){
    prozessName=$1
    buddyId=""
    gefunden=0
    for proz in "${prozesse[@]}"; do
        prozessNameInArray=$(echo "$proz" | cut -d',' -f2)
        #Wenn ein Prozess im Prozesses Array gefunden wurde,...
        if [[ "$prozessName" == "$prozessNameInArray" ]]; then
            prozessId=$(echo "$proz" | cut -d',' -f1)
            buddyId=$(echo "$proz" | cut -d',' -f4)
            #... wird dieser aus dem Array entfernt
            unset 'prozesse[prozessId]'
            prozesse=("${prozesse[@]}")
            gefunden=1
            #Fall kein Prozess gefunden wurde, wird eine Fehlermeldugn angezeigt
             if [[ $gefunden -eq 0 ]]; then        
                    message="Prozess $prozessName konnte nicht gelöscht werden, da dieser Prozess nicht existiert."
                    echo $message
                    log "$message" 
             fi
        fi
    done
    
    #Im vorletzen Schritt muss belegt wieder auf 0 gesetzt werden
    arrayId=$(getArrayIndexByyBuddyId $buddyId)
    zugewiesenerBuddy="${buddies[arrayId]}"
    
    
    buddyPairIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f2)
    groesse=$(echo "$zugewiesenerBuddy" | cut -d',' -f3)
    belegt=0
    parentContainerIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f5)
    buddies[arrayId]="$buddyId,$buddyPairIndex,$groesse,$belegt,$parentContainerIndex"
    
    #Zuletzt wird überpr+ft, ob buddies wieder zusammengefügt werden können
    buddiesZusammenfügen
    
}

#Fügt einem neune Prozess zu
addProzess(){
    #Der zuvor gefundene Budyy wird hier entgegengenommen...
    zugewiesenerBuddy=$1
    #...und seine Index aus dem Arrray gelesen
    zugewiesenerBuddyIndex=$(getIndex $zugewiesenerBuddy)
    buddyIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f1)
    buddyPairIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f2)
    neueGroesse=$(echo "$zugewiesenerBuddy" | cut -d',' -f3)
    belegt=1
    parentContainerIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f5)
    
    #Zunächst wird der Buddy auf belegt gesetzt
    buddies[zugewiesenerBuddyIndex]="$buddyIndex,$buddyPairIndex,$neueGroesse,$belegt,$parentContainerIndex"
    #und ein neuer Prozess, mit der Refferenz auf seinen dazugehörigen Buddy, hinzugefügt
    prozesse+=("$prozessId,$prozess,$buddyIndex")
    ((prozessId++))
    message="Prozess $prozess wurde dem Buddy mit der ID $buddyIndex erfolgreich zugewisen"
    echo $message
    echo
    log "$message"
}

#Entfernt den Buddy and der Stelle i und bereinigt das Array (Neuordnung der Indizes)
unsetBuddy(){
    i=$1
    unset 'buddies[i]'
    buddies=("${buddies[@]}")
}

#gibt den Array Index für das Gesamte Buddy element zurück
getIndex(){
    index=0
    for i in "${!buddies[@]}"; do
        if [[ "${buddies[i]}" == "$1" ]]; then
            index=$i
        fi
    done
    echo $index
}

sucheFreienBuddy(){
    #Es wird zunächst die Größe des Prozesses übergeben
    prozessgroesse=$1
    anfangsPotenz=$(calculateNextHigherPowerOfTwo $prozessgroesse)
    potenz=0
    buddyfound=0
    gefudeneBuddy=""
    #Wenn die prozessgroesse <= Speicherplatz und prozessgroesse > 0 ist...
    if [[ $prozessgroesse -le $speicherplatz  &&  $prozessgroesse -gt 0 ]]; then
    #... dann wird die nächsthöhere zweierpotenz der Prozessgröße berechnet
        potenz=$(calculateNextHigherPowerOfTwo $prozessgroesse)
        #Solange kein Buddy im Buddies Array gefunden wurde, der...
        while [[ $potenz -le $speicherplatz && $buddyfound -eq 0 ]]; do
            for buddy in "${buddies[@]}"; do
                buddygroesse=$(echo "$buddy" | cut -d',' -f3)
                buddyBelegt=$(echo "$buddy" | cut -d',' -f4)
                #...frei ist und die richitge Größe hat
                if [[ $buddygroesse -eq $potenz && $buddyBelegt -eq 0 ]]; then
                #wurde ein richitger Buddy gefunden wird buddyfound aud 1 gesetzt...
                    buddyfound=1
                    gefudeneBuddy=$buddy
                    break 2
                fi
            done
            # Falls kein passender Buddy gefunden wurde, 
            #wird die Potenz um die nächste Potenz-von-2 erhöht
            potenz=$((potenz * 2))
        done
        if [ $anfangsPotenz -eq $potenz ]; then
        #und der Prozess zum gefundenen Buddy hinzugefügt
            addProzess $gefudeneBuddy
        else
        #Gibt es im gesamten Array kein einzelnen Buddy der frei ist bzw. die
        #richtige Größe für den Prozess hat,so wird verucht eine Buddy zu teilen
            teileBuddy $gefudeneBuddy $prozessgroesse
        fi
    else
        message="Prozess konnte nicht hinzugefügt werden. Prozessgröße muss kleiner gleich der Speicherplatzgröße und größer 0 sein"
        echo $message
        log $message
    fi
}

#sucht in Prozesses Array nach dem Prozessnamen mithikfe der gegebenen BuddyID
getProzessnameByBuddyId(){
    buddyId=$1
    for prozess in "${prozesse[@]}"; do
        buddyIdinProzess=$(echo "$prozess" | cut -d',' -f4 )  
        if [[ $buddyId -eq $buddyIdinProzess ]]; then
        prozessName=$(echo "$prozess" | cut -d',' -f2 ) 
        prozessgroesse=$(echo "$prozess" | cut -d',' -f3 )  
        echo $prozessName $prozessgroesse
        fi
    done 
}

#Zeigt nach jedem Schritt (add/remove) an welceh Buddies es gibt, und wenn ja, auch die dazugehörigne Prozessnamen
ausgabeBuddy(){
    printf "%-15s %-20s %-17s %-17s %-15s\n" "Buddy Index" "Buddypaar Index" "Buddygröße" "Prozessname" "Prozessgröße"
    printf "%-15s %-20s %-15s %-17s %-15s\n" "-----------" "---------------" "------------" "-----------" "------------"
    for buddy in "${buddies[@]}"; do
    buddyIndex=$(echo "$buddy" | cut -d',' -f1 )
    buddyPairIndex=$(echo "$buddy" | cut -d',' -f2 )
    buddygroesse=$(echo "$buddy" | cut -d',' -f3 )
    belegt=$(echo "$buddy" | cut -d',' -f4 )
    prozessName=""
    prozessgroesse=""
    
    if [[ $belegt -eq 1 ]]; then
        buddyId=$(echo "$buddy" | cut -d',' -f1 )
        prozess=$(getProzessnameByBuddyId $buddyId)     
        read -r prozessName prozessgroesse <<< "$prozess"
    fi
        printf "%-15s %-20s %-15s %-17s %-15s\n" "$buddyIndex" "$buddyPairIndex" "$buddygroesse" "$prozessName" "$prozessgroesse"
    done
}

#Diese Methode liest alle add und Remove Befehle aus der vom Befehl eingelesenen prozessdatei
readFile() {
    while IFS= read -r line || [[ -n $line ]]; do
    #Hier wird der Befel (add/remove), der Prozessname, sowie die Prozessgröße geteilt
    log "$line"
        line=$(echo "$line" | tr -d '\r')
        anweisung=$(echo "$line" | cut -d' ' -f1)
        prozess=$(echo "$line" | cut -d' ' -f2)
        prozessgroesse=$(echo "$prozess" | cut -d',' -f2)
        #Wenn die Anweisung add lautet und die speicherverwaltung static ist, rufen wir die addProzessStatic Methode auf
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "static" ]]; then
        neuerName=$(checkIfProzessNameIsUnique "$prozess")
        prozess=$neuerName,$prozessgroesse
            addProzessStatic "$prozess"
            ausgabe
        fi
         #Wenn die Anweisung remove lautet und die speicherverwaltung static oder dynamic ist, rufen wir die removeProzess Methode auf
        if [[ "$anweisung" == 'remove' && $speicherverwaltung != "buddy" ]]; then
            removeProzess "$prozess"
            ausgabe
        fi
        #Wenn die Anweisung add lautet und die speicherverwaltung dynamic ist, rufen wir die addProzessDynamic Methode auf
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "dynamic" ]]; then
        neuerName=$(checkIfProzessNameIsUnique "$prozess")
        prozess=$neuerName,$prozessgroesse
            addProzessDynamic "$prozess"
            ausgabe
        fi
        #Wenn die Anweisung add lautet und die speicherverwaltung buddy ist, rufen wir die sucheFreienBuddy Methode auf
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "buddy" ]]; then
        echo $line
        sucheFreienBuddy $prozessgroesse
        ausgabeBuddy
        echo
        fi
        #Wenn die Anweisung remove lautet und die speicherverwaltung buddy ist, rufen wir die removeProzessBuddy Methode auf
        if [[ "$anweisung" == 'remove' && $speicherverwaltung == "buddy" ]]; then
        #muss auf name statt id angepasst werden
        echo $line
        removeProzessBuddy "$prozess"
        ausgabeBuddy
        fi
        echo
    done < "$prozessdatei"
}

calculateNextHigherPowerOfTwo() {
    num=$1
    #Hier überprüfen wir, ob die übergene Zahl bereits eine Zweierpotenz ist
    #Dabei wird die übergebene Zahl in bits umgewnadelt und durch das (num -1) invertiert
    #Beispiel num=8 1000  num -1 = 0111
    #Dann wird die invertierte Zahl mit der Originalzahl AND-verknüpft
    #Wenn das Ergebnis 0 ist, ist die Zahl eine Zweierpotenz
    if (( (num & (num - 1)) == 0 )); then
        echo $num
        return
    fi
    
    power=1
    #Ist die Zahk keine Zweierpotenz wird die übergebene Zahl solange durch 2 geteilt, bis sie größer als 1 ist,
    #um den Exponenten der nächst höheren Zweierpotenz zu finden
    while (( num > 1 )); do
        num=$((num / 2))
        ((power++))
    done
    #Die nächst höhere Zweierpotenz wird dann mithilfe des Exponenten potenziert
    potenz=$(echo "2^$power" | bc)
    echo $potenz
}

#Mithilfe dieser methode überprüfen wir dass der Benutzer bei Abfrage der Speichergröße und Partition nur Integer (Ganzzahlen) eingeben darf
is_integer() {
    local s="$1"
    if [[ "$s" =~ ^-?[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

#Bei falscher Benutzung des Befehls wird diese Infor ausgegeben
info() {
    echo "Usage:"
    echo "  simulator.sh -speicherverwaltung [static|dynamic|buddy] -prozessdatei <file> -logdatei <file>"
    echo "  simulator.sh -speicherverwaltung dynamic -konzept <best|first|next> -prozessdatei <file> -logdatei <file>"
    echo "Options:"
    echo "  -speicherverwaltung   (static, dynamic, buddy)"
    echo "  -konzept              Allocation strategy (best, first, next) [only for dynamic]"
    echo "  -prozessdatei      Hier wird die Datei eingelesen, in der die Prozesse stehen, die gestartet pder beendet werden sollen."
    echo "  -logdatei          In dieser Datei werden alle wichtigen Schritte beim Aausführen der Simulation gespeichert.  "
}

#Interne Fragmentierung tritt bei der statischen Partitionierung auf
#Es wird dabei jede Partition durchlaufen und wenn ein Prozess drin gespeichert ist,
#wird die Differenz zwischen Prozessgröße und Partitionsgröße berechnet.
#Diese wird dann in internefragmentierung immer draufaddiert und so erhält man die Größe der internen Fragmentierung
internefragmentierungBerechnen(){
    for ((i=1; i<=matrixLaenge; i++)); do
            prozess="${matrix[$i,2]}"
            prozessgroesse=$(echo "$prozess" | cut -d',' -f2)
            internefragmentierung=$(( internefragmentierung + partition - prozessgroesse))
    done
}

#Um die externe Fragmentierung zu berechen, durchläuft mnan alle Positionen in der Matrix 
#und inkrementiert die externeFragmentierung Variable
externeFragmentierungBerechnen(){
     for ((i=1; i<=matrixLaenge; i++)); do
         if [[ -z "${matrix[$i,2]}" ]]; then
            ((externeFragmentierung++))
         fi
        done
        keineFragmentierung=$((speicherplatz - letzeIndexFragmentierung + 1))
        externeFragmentierung=$((externeFragmentierung - keineFragmentierung))
}

#Für die interne Fragmentierung wird das Array aler Prozesse durhclaufen
#und die Differenz zwischen Prozessgröße und Prozessgröße in Potenz berechnet
interenFragmentierungBuddy(){
for prozess in "${prozesse[@]}"; do
     prozessgroesse=$(echo "$prozess" | cut -d',' -f3 )  
     prozessgroessePotenz=$(calculateNextHigherPowerOfTwo $prozessgroesse)
     internefragmentierung=$((internefragmentierung + prozessgroessePotenz - prozessgroesse)) 
    done 
}
 
#Hier zählt man die Größe aller Buddys zusammen, die von keinem Prozess belegt werden
externeFragmentierungBuddy(){
    for buddy in "${buddies[@]}"; do
    belegt=$(echo "$buddy" | cut -d',' -f4 )
    
    if [[ $belegt -eq 0 ]]; then
        buddygroesse=$(echo "$buddy" | cut -d',' -f3 )
        externeFragmentierung=$((externeFragmentierung + buddygroesse))
    fi
    done
}

#Um die Buddy Funktionalität von den Partitionierungsmethoden zu kapseln haben wird die buddysimulation verwendet
buddySimulation(){
message="Die buddy Speicherverwaltung  wurde mit einem $speicherplatz MB großen Speicherplatz gestartet"
echo $message
echo
log "$message"
log "Es werden die Prozesses aus der $prozessdatei gelesen"
readFile
interenFragmentierungBuddy
externeFragmentierungBuddy
message="Die interne Fragmentierung beträgt $internefragmentierung MB und die externe Fragmentierung bezrägt $externeFragmentierung"
echo $message
log "$message"
log "---------------------------------------"
exit
}

#Diese Methode ermöglich das generische Schreiben von Nachrichten in die vom Benutzr definierten Log-Datei
log() {
  local logText="$1"
  #Es wirdimmer eine Nachricht übergeben, und davor wird das Datum angezeigt
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $logText" >> "$logdatei"
}

#Glpbale statische und dynamische Variablen
speicherverwaltung=""
konzept=""
prozessdatei=""
logdatei=""

matrixLaenge=""
lastindex=1

internefragmentierung=0
externeFragmentierung=0

letzeIndexFragmentierung=0

#Globale buddy Variablen
buddyIndex=0
buddyPairIndex=0
belegt=0

prozessId=0

buddies=()
prozesse=()
parents=()

parents+=(0,0)

# Hiermit werden die Argumente aus dem Befehl in der Console eingelesen
while [[ $# -gt 0 ]]; do
    key="$1"
    
    case $key in
        -speicherverwaltung)
            speicherverwaltung="$2"
            shift 2
        ;;
        -prozessdatei)
            prozessdatei="$2"
            shift 2
        ;;
        -logdatei)
            logdatei="$2"
            shift 2
        ;;
        -konzept)
            konzept="$2"
            shift 2
        ;;
        *)
            echo "Unknown option: $1"
            info
            exit 1
        ;;
    esac
done

#Fehlermeldung wenn eine übergreifendes Argument im Befehl fehlt
if [[ -z "$speicherverwaltung" || -z "$prozessdatei" || -z "$logdatei" ]]; then
    echo "Error: Es fehlen einige Argumente."
    info
    exit 1
fi

if [[ "$speicherverwaltung" == "static" ]]; then
    echo "Die statische Partitionierung wird gestartet."
    elif [[ "$speicherverwaltung" == "dynamic" ]]; then
    if [[ -z "$konzept" ]]; then
        #Fehlermeldung wenn das Argument für das Konzept im Befehl für die dynamische Partitionierung fehlt
        echo "Error: Es fehlt das -konzept Argument für die dynamische Partitionierung."
        info
        exit 1
    fi
    echo "Die dynamische Partitionierung wird mit dem Konzept: $konzept gestartet."
    elif [[ "$speicherverwaltung" == "buddy" ]]; then
    echo "Die Buddy-Speicherverwaltung wird gestartet"
    echo
    #Fehlermeldung wenn das Argumetn für die Speicherverwaltung fehlt oder falsch geschrieben wurde
else
    echo "Error: Es fehlt das Argument für die -speicherverwaltung x. Es muss zwichen static, dynamic, oder buddy gewählt werden."
    info
    exit 1
fi

#Hier wird die logdatei erstellt falls diese noch nicht exsistiert
if [ ! -f "$logdatei" ]; then
  touch "$logdatei"
  echo "Logdatei: $logdatei wurde erstellt."
fi

#Als erstes wird vom Benutzer die Speicherplatzgröße eingelesen
read -p "Geben Sie die Größe des Speicherplatzes ein: " speicherplatz

#... diese muss eine Int und größere 0 sein
if ! is_integer "$speicherplatz" || [[ $speicherplatz -lt 0 ]]; then
    echo "Error: Speicherplatz muss eine ganze Zahl (Integer) größer 0 sein."
    exit 1
fi

#Wenn buddy als Speicherverwaltungm asugewählt wurde, nehmen wir die nächsthöhere Potenz des übergebenen Speichers...
if [[ "$speicherverwaltung" == "buddy" ]]; then
speicherplatz=$(calculateNextHigherPowerOfTwo $speicherplatz)
buddies+=("$buddyIndex,$buddyPairIndex,$speicherplatz,$belegt,$buddyIndex")
#...und starten die buddy Simulation
buddySimulation
fi

#Für die statische Speicherverwaltung wird nochd ie Partitionsgröße eingelesen, muss hier auch ein Int und größer 0 sein
if [[ "$speicherverwaltung" == "static" ]]; then
read -p "Geben sie die Größe der einzelnen Partitionen ein: " partition

if ! is_integer "$partition" || [[ $partition -lt 0 ]]; then
    echo "Error: Die Partitionsgröße muss eine ganze Zahl (Integer) größer 0 sein."
    exit 1
fi

#Die Anzahl der Partitionen wir hier ausgrechnet, indem man den gesamten Speicher durch die Partitionsgröße teilt
matrixLaenge=$(($speicherplatz / $partition))
echo 
fi

#Die Auswahl der Speicherverwaltung, des Speicherplatzes wird hier gelogt und ausgegeben
message="Die speicherverwaltung $speicherverwaltung wurde mit einem $speicherplatz MB großen Speicherplatz gestartet"
echo $message
echo
log "$message"
if [[ "$speicherverwaltung" == "static" ]]; then
#Die Partitionsgröße und die Anzahl der Partitionen werden hier gelogt und ausgegeben
message="Die einzelnen Partitionen sind $partition MB groß. Somit gibt es $matrixLaenge gleich große Partitionen"
echo $message
echo
log "$message"
fi

#Das dynamic Konzept wird hier gelogt und ausgegeben
if [[ "$speicherverwaltung" == "dynamic" ]]; then
message="Das Konzept $konzept wurde ausgewählt"
echo $message
echo
log "$message"
fi

#Die Matrixlänge soll hier die Speicherplaztgröße und nicht die Anzahl der Partitionen sein
if [[ $speicherverwaltung == "dynamic" ]];then
    matrixLaenge=$speicherplatz
fi

declare -A matrix

#Hier wird eine zweidimensionale Matrix definiert
#Bei der statischen Partitionierung ist die Länge der Matrix , also die Anzahl der Zeilen), gleich der Anzahl an Partitonen
#In der ersten Spalte wird i als Zähler hochgezählt um auf die Prozesse später zugreifen zu können
#und in der zweiten Spalte speichern wir die zugewiesenen Prozesse
for ((i=1; i<=matrixLaenge; i++)); do
    matrix[$i,1]=$i
    matrix[$i,2]=""
done

message="Es werden die Prozesses aus der $prozessdatei gelesen"
echo $message
echo
log "$message"
#In dieser Methode wwerden die Prozesse über eine .txt Datei eingelesen und Prozesse erstellt bzw. terminiert
readFile

#Hier wird die interne Fragmentierung Methode aufgerugen für die statische Speicherverwaltung
if [[ $speicherverwaltung == "static" ]];then
internefragmentierungBerechnen
message="Die interne Fragmentierung beträgt $internefragmentierung MB"
echo $message
log "$message"

fi

#Hier wird die externe Fragmentierung Methode aufgerugen für die dynamische Speicherverwaltung
if [[ $speicherverwaltung == "dynamic" ]];then
externeFragmentierungBerechnen
message="Die externe Fragmentierung beträgt $externeFragmentierung MB"
echo $message
log "$message"
fi

log "---------------------------------------"
