#!/bin/bash
bestFit(){
     start=0
    ende=0
    fitOptions=()
    leerzaehler=0
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
            if [[ -z "${matrix[$i,$j]}" ]]; then
              ((leerzaehler++))
            fi
            if [[ $i -eq 128 || -n "${matrix[$i,$j]}" ]]; then
              if [[ $leerzaehler -ge $1 ]]; then
                ende=$((i))
                start=$((i - leerzaehler + 1))
              if [[ $i -lt 128 ]];then
                ende=$((i - 1))
                start=$((i - leerzaehler))
              fi
                fitOptions+=("$start","$ende")
              fi
                leerzaehler=0
            fi
        done
    done

    if [ ${#fitOptions[@]} -eq 0 ]; then
        echo "No fit options found."
        return
    fi

    start=0
    ende=0   

    for option in "${fitOptions[@]}"; do
        anfangArray=$(echo "$option" | cut -d',' -f1)
        endeArray=$(echo "$option" | cut -d',' -f2)
        size=$((endeArray - anfangArray + 1))

        if [[ $size -le $matrixLaenge ]]; then
            start=$anfangArray
            ende=$((start + $1 - 1))
            matrixLaenge=$size
        fi
    done
        
     echo "$start $ende" 
}

firstNextFist(){
    startPunkt=1
    prozessgroesse=$1
    if [ "$konzept" == "next" ];then
        startPunkt=$2
    fi
    freieStelleCounter=$1;
    start=0
    ende=0
    for ((i=$startPunkt; i<=matrixLaenge; i++)); do
        if [[ -z "${matrix[$i,2]}"  && $freieStelleCounter -gt 0 ]]; then
           ((freieStelleCounter -= 1))
          ende=$i
        fi
        if [[ -n "${matrix[$i,2]}"  ]]; then
            freieStelleCounter=$1
        fi
        if [[ $freieStelleCounter -eq 0  ]]; then 
            start=$((ende - prozessgroesse + 1))
            echo "$start $ende"
            break 3
        fi
        if [[ $freieStelleCounter -gt 0 && i -ge $matrixLaenge  ]]; then
            startPunkt=1
            matrixLaenge=$2
            freieStelleCounter=$1
            i=$startPunkt
        fi
    done
}

addProzessDynamic() {
    pgroesse=$(echo "$1" | cut -d',' -f2 | tr -dc '0-9' )
    prozessName=$(echo "$1" | cut -d',' -f1)
    if [[ "$konzept" == "first" || "$konzept" == "next" ]]; then
    startEnde=$(firstNextFist $pgroesse $lastindex)
    fi
    if [[ "$konzept" == "best" ]]; then
    startEnde=$(bestFit $pgroesse)
    fi
    read -r start ende <<< "$startEnde"
    lastindex=$((ende + 1))
    if [[ $lastindex  -gt $letzeIndexFragmentierung ]];then
    letzeIndexFragmentierung=$lastindex
    fi
    for ((i=start; i<=ende; i++)); do
        for ((j=2; j<=2; j++)); do
                matrix[$i,$j]=$prozessName
        done
    done
     if [[ $start -gt 0 ]]; then
    message="Der Prozess $prozessName wurde erfolgreich hinzugefügt"
            echo $message
            log "$message"
    fi

}

addProzessStatic() {
    platzgefunden=0
    prozessName=$(echo "$1" | cut -d',' -f1)
    pgroesse=$(echo "$1" | cut -d',' -f2 | tr -dc '0-9' )
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
            if [[ -z "${matrix[$i,$j]}" && $platzgefunden -eq 0 && $pgroesse -le $partition ]]; then
                matrix[$i,$j]=$1
                platzgefunden=1
                message="Der Prozess $prozessName wurde erfolgreich hinzugefügt"
                echo $message
                log $message
            fi
            if [[ $pgroesse -gt $partition ]]; then
                message="$prozessName konnte nicht hinzugefügt werden. Der Prozess mit der Größe $pgroesse MB ist zu groß für die Patritionsgröße ($partition MB)."
                log "$message"
                echo $message
                return
            fi
        done
    done
        if [[ $platzgefunden -eq 0 ]]; then
               message="$prozessName konnte nicht hinzugefügt werden. Alle Partitionen sind bereits belegt."
                log "$message"
                echo $message
        fi
}

removeProzessStatic() {
    deleted=false
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
            prozess="${matrix[$i,$j]}"
            matrixProzess=$(echo "$prozess" | cut -d',' -f1 )
            if [[ "$matrixProzess" == "$1" ]]; then
                matrix[$i,$j]=""
                deleted=true
            fi
        done
    done
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

checkIfProzessNameIsUnique() {
     prozessName=$(echo "$1" | cut -d',' -f1)
    log "Überprüfe ob der Prozessname $prozessName eindeutig ist "
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
             prozessInMatrix="${matrix[$i,$j]}"
             prozessNameInMatrix=$(echo "$prozessInMatrix" | cut -d',' -f1)
            if [[ "$prozessName" == "$prozessNameInMatrix" ]]; then
             read -p "Der Prozessname $prozessName existiert bereits. Bitte gib einen neuen Prozessnamen ein: " neuerProzessName </dev/tty
             log "Der Prozess mit dem namen $prozessName existiert bereits und wurde zu $neuerProzessName geändert"
             neuerName=$(checkIfProzessNameIsUnique "$neuerProzessName") # Überprüfe den neuen Namen
            echo "$neuerName"
            
                return # Funktion beenden und neuen Namen zurückgeben
            fi
        done
    done
    log "Der Prozessname $prozessName ist eindeutig."
    echo "$prozessName" # Wenn kein doppelter Name gefunden wurde, gib den ursprünglichen Namen zurück
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

teileBuddy(){
    oldBuddy=$1
    parentContainerIndex=$(echo "$oldBuddy" | cut -d',' -f2)
    buddygroesse=$(echo "$oldBuddy" | cut -d',' -f3)
    
    oldBuddyIndex=$(getIndex $oldBuddy)
    unsetBuddy $oldBuddyIndex
    
    neueGroesse=$((buddygroesse / 2))
    ((buddyIndex++))
    ((buddyPairIndex++))
    buddies+=("$buddyIndex,$buddyPairIndex,$neueGroesse,0,$parentContainerIndex")
    ((buddyIndex++))
    buddies+=("$buddyIndex,$buddyPairIndex,$neueGroesse,0,$parentContainerIndex")
    
    parents+=($buddyPairIndex,$parentContainerIndex)
    #teiel buddy rekursive aufrufgen bis wir ein budy geteilt haben der sp groß ist wie wir ihn bruachen
    #wenn getteilt dann erst suceh freienbuddy aufrufen
    
    sucheFreienBuddy $2
}

unsetParent(){
    for parent in "${!parents[@]}"; do
        removeParentIndex=$(echo "$parent" | cut -d',' -f1)
        if [ "$removeParentIndex" == "$1" ]; then
            unset "parents[$parent]"
            parents=("${parents[@]}")
        fi
    done
}

getOldParentByParentIndex(){
    for p in "${parents[@]}"; do
        parentIndex=$(echo "$p" | cut -d',' -f1)
        if [ "$parentIndex" == "$1" ]; then
            oldParentIndex=$(echo "$p" | cut -d',' -f2)
        fi
    done
    echo $oldParentIndex
    
}

buddiesZusammenfügen(){
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
                if [[ $comparedBelegt -eq 0 && $buddyId -ne $comparedBuddyIndex
                    && $buddyPairIndex -eq $comparedBuddyPairIndex ]];then
                    
                    oldparent=$(getOldParentByParentIndex $parentIndex)
                    
                    unsetParent $buddyPairIndex                    
                    
                    buddies+=("$buddyIndex,$parentIndex,$buddygroesse,0,$oldparent")
                    firstBuddyArrayIndex=$(getIndex $buddy)
                    unsetBuddy $firstBuddyArrayIndex
                    secondBuddyArrayIndex=$(getIndex $comparedBuddy)
                    unsetBuddy $secondBuddyArrayIndex
                    
                    buddiesZusammenfügen
                    break 2
                    
                fi
            done
        fi
    done
}

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

removeProzessBuddy(){
    prozessName=$1
    buddyId=""
    for proz in "${prozesse[@]}"; do
        prozessNameInArray=$(echo "$proz" | cut -d',' -f2)
        if [[ "$prozessName" == "$prozessNameInArray" ]]; then
            prozessId=$(echo "$proz" | cut -d',' -f1)
            buddyId=$(echo "$proz" | cut -d',' -f4)
            unset 'prozesse[prozessId]'
            prozesse=("${prozesse[@]}")
            #gefuned=true wenn fasle geh untenin else
            # else            
            # message="Prozess $prozessName konnte nicht gelöscht werden, da dieser Prozess nicht existiert."
            # echo $message
            # log "$message" 
        fi
    done
    
    arrayId=$(getArrayIndexByyBuddyId $buddyId)
    zugewiesenerBuddy="${buddies[arrayId]}"
    
    
    buddyPairIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f2)
    groesse=$(echo "$zugewiesenerBuddy" | cut -d',' -f3)
    belegt=0
    parentContainerIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f5)
    buddies[arrayId]="$buddyId,$buddyPairIndex,$groesse,$belegt,$parentContainerIndex"
    
    buddiesZusammenfügen
    
}

addProzess(){
    zugewiesenerBuddy=$1
    zugewiesenerBuddyIndex=$(getIndex $zugewiesenerBuddy)
    buddyIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f1)
    buddyPairIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f2)
    neueGroesse=$(echo "$zugewiesenerBuddy" | cut -d',' -f3)
    belegt=1
    parentContainerIndex=$(echo "$zugewiesenerBuddy" | cut -d',' -f5)
    
    buddies[zugewiesenerBuddyIndex]="$buddyIndex,$buddyPairIndex,$neueGroesse,$belegt,$parentContainerIndex"
    prozesse+=("$prozessId,$prozess,$buddyIndex")
    ((prozessId++))
}

unsetBuddy(){
    i=$1
    unset 'buddies[i]'
    buddies=("${buddies[@]}")
}
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
    prozessgroesse=$1
    anfangsPotenz=$(calculateNextHigherPowerOfTwo $prozessgroesse)
    potenz=0
    buddyfound=0
    gefudeneBuddy=""
    if [ $prozessgroesse -le $speicherplatz ] && [ $prozessgroesse -gt 0 ]; then
        potenz=$(calculateNextHigherPowerOfTwo $prozessgroesse)
        while [[ $potenz -le $speicherplatz && $buddyfound -eq 0 ]]; do
            for buddy in "${buddies[@]}"; do
                buddygroesse=$(echo "$buddy" | cut -d',' -f3)
                buddyBelegt=$(echo "$buddy" | cut -d',' -f4)
                if [[ $buddygroesse -eq $potenz && $buddyBelegt -eq 0 ]]; then
                    buddyfound=1
                    gefudeneBuddy=$buddy
                    break 2
                fi
            done
            # Falls kein passender Buddy gefunden wurde, erhöhe die Potenz um das nächste Potenz-von-2
            potenz=$((potenz * 2))
        done
        if [ $anfangsPotenz -eq $potenz ]; then
            addProzess $gefudeneBuddy
        else
            teileBuddy $gefudeneBuddy $prozessgroesse
        fi
    else
        message="Prozess konnte nicht hinzugefügt werden. Prozessgröße muss kleiner gleich der Speicherplatzgröße und größer 0 sein"
        echo $message
        log $message
    fi
}
getProzessnameByBuddyId(){
    buddyId=$1
    for prozess in "${prozesse[@]}"; do
        buddyIdinProzess=$(echo "$prozess" | cut -d',' -f4 )  
        if [[ $buddyId -eq $buddyIdinProzess ]]; then
        prozessName=$(echo "$prozess" | cut -d',' -f2 )  
        echo $prozessName
        fi
    done 
}

ausgabeBuddy(){
    printf "%-15s %-20s %-17s %-15s\n" "Buddy Index" "Buddypaar Index" "Prozessgröße" "Prozessname"
    printf "%-15s %-20s %-15s %-15s\n" "-----------" "---------------" "------------" "-----------"
    for buddy in "${buddies[@]}"; do
    buddyIndex=$(echo "$buddy" | cut -d',' -f1 )
    buddyPairIndex=$(echo "$buddy" | cut -d',' -f2 )
    prozessgroesse=$(echo "$buddy" | cut -d',' -f3 )
    belegt=$(echo "$buddy" | cut -d',' -f4 )
    prozessName=""
    
    if [[ $belegt -eq 1 ]]; then
     buddyId=$(echo "$buddy" | cut -d',' -f1 )
    prozessName=$(getProzessnameByBuddyId $buddyId)
    fi
       printf "%-15s %-20s %-15s %-15s\n" "$buddyIndex" "$buddyPairIndex" "$prozessgroesse" "$prozessName"
    done
}

readFile() {
    while IFS= read -r line || [[ -n $line ]]; do
    log "$line"
        line=$(echo "$line" | tr -d '\r')
        anweisung=$(echo "$line" | cut -d' ' -f1)
        prozess=$(echo "$line" | cut -d' ' -f2)
        prozessgroesse=$(echo "$prozess" | cut -d',' -f2)
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "static" ]]; then
        neuerName=$(checkIfProzessNameIsUnique "$prozess")
        prozess=$neuerName,$prozessgroesse
            addProzessStatic "$prozess"
            ausgabe
        fi
        if [[ "$anweisung" == 'remove' && $speicherverwaltung != "buddy" ]]; then
            removeProzessStatic "$prozess"
            ausgabe
        fi
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "dynamic" ]]; then
        neuerName=$(checkIfProzessNameIsUnique "$prozess")
        prozess=$neuerName,$prozessgroesse
            addProzessDynamic "$prozess"
            ausgabe
        fi
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "buddy" ]]; then
        echo $line
        sucheFreienBuddy $prozessgroesse
        ausgabeBuddy
        echo
        fi
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
    #Hier überprüfen wir, ob der Speicher bereits eine Zweierpotenz ist
    #Dabei wird der übergebene Speicher in bits umgewnadelt und durch das (num -1) invertiert
    #Beispiel num=8 1000  num -1 = 0111
    #Dann wird die invertierte Zahl mit der Originalzahl AND-verknüpft
    #Wenn das Ergebnis 0 ist, ist die Zahl eine Zweierpotenz
    if (( (num & (num - 1)) == 0 )); then
        echo $num
        return
    fi
    
    power=1
    #Ist der Speicher keine Zweierpotenz wird die übergebene Zahl solange durch 2 geteilt, bis sie größer als 1 ist,
    #um den Exponenten der nächst höheren Zweierpotenz zu finden
    while (( num > 1 )); do
        num=$((num / 2))
        ((power++))
    done
    #Die nächst höhere Zweierpotenz wird dann mithilfe des Exponenten potenziert
    potenz=$(echo "2^$power" | bc)
    echo $potenz
}

is_integer() {
    local s="$1"
    if [[ "$s" =~ ^-?[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

info() {
    echo "Usage:"
    echo "  simulator.sh -speicherverwaltung [static|dynamic|buddy] -prozessdatei <file> -logdatei <file>"
    echo "  simulator.sh -speicherverwaltung dynamic -konzept <best|first|next> -prozessdatei <file> -logdatei <file>"
    echo "Options:"
    echo "  -speicherverwaltung   (static, dynamic, buddy)"
    echo "  -konzept              Allocation strategy (best, first, next) [only for dynamic]"
    echo "  -prozessdatei      Hier wird die Datei eingelesen, in der die Prozesse stehen, die gestartet pder beendet werden sollen."
    echo "  -logdatei             "
}

internefragmentierungBerechnen(){
    for ((i=1; i<=matrixLaenge; i++)); do
            prozess="${matrix[$i,2]}"
            prozessgroesse=$(echo "$prozess" | cut -d',' -f2)
            internefragmentierung=$(( internefragmentierung + partition - prozessgroesse))
        done
}

externeFragmentierungBerechnen(){
     for ((i=1; i<=matrixLaenge; i++)); do
         if [[ -z "${matrix[$i,2]}" ]]; then
            ((externeFragmentierung++))
         fi
        done
        keineFragmentierung=$((speicherplatz - letzeIndexFragmentierung + 1))
        externeFragmentierung=$((externeFragmentierung - keineFragmentierung))
}

interenFragmentierungBuddy(){
for prozess in "${prozesse[@]}"; do
     prozessgroesse=$(echo "$prozess" | cut -d',' -f3 )  
     prozessgroessePotenz=$(calculateNextHigherPowerOfTwo $prozessgroesse)
     internefragmentierung=$((internefragmentierung + prozessgroessePotenz - prozessgroesse)) 
    done 
}
 

externeFragmentierungBuddy(){
    for buddy in "${buddies[@]}"; do
    belegt=$(echo "$buddy" | cut -d',' -f4 )
    
    if [[ $belegt -eq 0 ]]; then
        buddygroesse=$(echo "$buddy" | cut -d',' -f3 )
        externeFragmentierung=$((externeFragmentierung + buddygroesse))
    fi
    done
}

buddySimulation(){
log "Es werden die Prozesses aus der $prozessdatei gelesen"
readFile
interenFragmentierungBuddy
externeFragmentierungBuddy
message="Die interne Fragmentierung beträgt $internefragmentierung MB und die externe Fragmentierung bezrägt $externeFragmentierung"
echo $message
log "$message"
exit
}

log() {
  local logText="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $logText" >> "$logdatei"
}

speicherverwaltung=""
konzept=""
prozessdatei=""
logdatei=""

matrixLaenge=""
lastindex=1

internefragmentierung=0
externeFragmentierung=0

letzeIndexFragmentierung=0

#buddy
buddyIndex=0
buddyPairIndex=0
belegt=0

prozessId=0

buddies=()
prozesse=()
parents=()

parents+=(0,0)

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

if [[ -z "$speicherverwaltung" || -z "$prozessdatei" || -z "$logdatei" ]]; then
    echo "Error: Es fehlen einige Argumente."
    info
    exit 1
fi

if [[ "$speicherverwaltung" == "static" ]]; then
    echo "Die statische Partitionierung wird gestartet."
    elif [[ "$speicherverwaltung" == "dynamic" ]]; then
    if [[ -z "$konzept" ]]; then
        echo "Error: Es fehlt das -konzept Argument für die dynamische Partitionierung."
        info
        exit 1
    fi
    echo "Die dynamische Partitionierung wird mit dem Konzept: $konzept gestartet."
    elif [[ "$speicherverwaltung" == "buddy" ]]; then
    echo "Die Buddy-Speicherverwaltung wird gestartet"
    echo
else
    echo "Error: Es fehlt das Argument für die -speicherverwaltung x. Es muss zwichen static, dynamic, oder buddy gewählt werden."
    info
    exit 1
fi

if [ ! -f "$logdatei" ]; then
  touch "$logdatei"
  echo "Logdatei: $logdatei wurde erstellt."
fi

#Als erstes wird vom Benutzer die Speicherplatzgröße, sowie die Größe der Partitionen eingelesen
#Beide Werte werden auf die nächst höhere 2er Potenz gerundet
read -p "Geben Sie die Größe des Speicherplatzes ein: " speicherplatz

if ! is_integer "$speicherplatz" || [[ $speicherplatz -lt 0 ]]; then
    echo "Error: Speicherplatz muss eine ganze Zahl (Integer) größer 0 sein."
    exit 1
fi

if [[ "$speicherverwaltung" == "buddy" ]]; then
speicherplatz=$(calculateNextHigherPowerOfTwo $speicherplatz)
buddies+=("$buddyIndex,$buddyPairIndex,$speicherplatz,$belegt,$buddyIndex")
buddySimulation
exit
fi

if [[ "$speicherverwaltung" == "static" ]]; then
read -p "Geben sie die Größe der einzelnen Partitionen ein: " partition

if ! is_integer "$partition" || [[ $partition -lt 0 ]]; then
    echo "Error: Die Partitionsgröße muss eine ganze Zahl (Integer) größer 0 sein."
    exit 1
fi

#Die Anzahl der Partitionen wir hier ausgrechnet, indem wir den gesamten Speicher durch die Partitionsgröße teilen
matrixLaenge=$(($speicherplatz / $partition))
echo 
fi

log "Die speicherverwaltung: $speicherverwaltung wurde mit einem $speicherplatz MB großen Speicherplatz gestartet"
if [[ "$speicherverwaltung" == "static" ]]; then
log "Die einzelnen Partitionen sind $partition MB groß. Somit gibt es $matrixLaenge gleich große Partitionen"
fi
if [[ "$speicherverwaltung" == "dynamic" ]]; then
log "Das Konzept $konzept wurde ausgewählt"
fi


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

#In dieser Methode wwerden die Prozesse über eine .txt Datei eingelesen und Prozesse erstellt bzw. terminiert
log "Es werden die Prozesses aus der $prozessdatei gelesen"
readFile

if [[ $speicherverwaltung == "static" ]];then
internefragmentierungBerechnen
message="Die interne Fragmentierung beträgt $internefragmentierung MB"
echo $message
log "$message"

fi

if [[ $speicherverwaltung == "dynamic" ]];then
externeFragmentierungBerechnen
message="Die externe Fragmentierung beträgt $externeFragmentierung MB"
echo $message
log "$message"
fi


log "--------------------------------------------------------------------"
