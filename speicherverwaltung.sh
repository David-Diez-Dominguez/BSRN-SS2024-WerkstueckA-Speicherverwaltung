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
    prozessgroese=$1
    if [ "$konzept" == "next" ];then
        startPunkt=$2
    fi
    freieStelleCounter=$1;
    start=0
    ende=0
    for ((i=$startPunkt; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
        if [[ -z "${matrix[$i,$j]}"  && $freieStelleCounter -gt 0 ]]; then
           ((freieStelleCounter -= 1))
          ende=$i
        fi
        if [[ -n "${matrix[$i,$j]}"  ]]; then
        freieStelleCounter=$1
        fi
          if [[ $freieStelleCounter -eq 0  ]]; then 
            start=$((ende - prozessgroese + 1))
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
    # echo "Start: $start"
    # echo "Ende: $ende"
    lastindex=$((ende + 1))
    for ((i=start; i<=ende; i++)); do
        for ((j=2; j<=2; j++)); do
                matrix[$i,$j]=$prozessName
        done
    done
}

addProzessStatic() {
    platzgefunden=0
    prozessName=$(echo "$1" | cut -d',' -f1)
    pgroesse=$(echo "$1" | cut -d',' -f2 | tr -dc '0-9' )
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
            if [[ -z "${matrix[$i,$j]}" && $platzgefunden -eq 0 && $pgroesse -le $partitionsgroeseInpotenz ]]; then
                matrix[$i,$j]=$1
                platzgefunden=1
            fi
            if [[ $pgroesse -gt $partitionsgroeseInpotenz ]]; then
                message="$prozessName konnte nicht hinzugefügt werden. Der Prozess ist zu groß für die Patritionsgröße."
                echo $message
                break 3
            fi
        done
    done
}

removeProzessStatic() {
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
            prozess="${matrix[$i,$j]}"
            matrixProzess=$(echo "$prozess" | cut -d',' -f1 )
            if [[ "$matrixProzess" == "$1" ]]; then
                matrix[$i,$j]=""
            fi
        done
    done
}

checkIfProzessNameIsUnique() {
     prozessName=$(echo "$1" | cut -d',' -f1)
    for ((i=1; i<=matrixLaenge; i++)); do
        for ((j=2; j<=2; j++)); do
             prozessInMatrix="${matrix[$i,$j]}"
             prozessNameInMatrix=$(echo "$prozessInMatrix" | cut -d',' -f1)
            if [[ "$prozessName" == "$prozessNameInMatrix" ]]; then
             read -p "Der Prozessname $prozessName existiert bereits. Bitte gib einen neuen Prozessnamen ein: " neuerProzessName </dev/tty
             neuerName=$(checkIfProzessNameIsUnique "$neuerProzessName") # Überprüfe den neuen Namen
            echo "$neuerName"
            
                return # Funktion beenden und neuen Namen zurückgeben
            fi
        done
    done
    echo "$prozessName" # Wenn kein doppelter Name gefunden wurde, gib den ursprünglichen Namen zurück
}

readFile() {
    while IFS= read -r line || [[ -n $line ]]; do
        line=$(echo "$line" | tr -d '\r')
        anweisung=$(echo "$line" | cut -d' ' -f1)
        prozess=$(echo "$line" | cut -d' ' -f2)
        prozessgroese=$(echo "$prozess" | cut -d',' -f2)
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "static" ]]; then
        neuerName=$(checkIfProzessNameIsUnique "$prozess")
        prozess=$neuerName,$prozessgroese
            addProzessStatic "$prozess"
         elif [[ "$anweisung" == 'remove' ]]; then
            removeProzessStatic "$prozess"
        fi
        if [[ "$anweisung" == 'add' && $speicherverwaltung == "dynamic" ]]; then
        neuerName=$(checkIfProzessNameIsUnique "$prozess")
        prozess=$neuerName,$prozessgroese
            addProzessDynamic "$prozess"
        fi
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

speicherverwaltung=""
konzept=""
prozessdatei=""
logdatei=""

matrixLaenge=""
lastindex=1


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
else
    echo "Error: Es fehlt das Argument für die -speicherverwaltung x. Es muss zwichen static, dynamic, oder buddy gewählt werden."
    info
    exit 1
fi


#Als erstes wird vom Benutzer die Speicherplatzgröße, sowie die Größe der Partitionen eingelesen
#Beide Werte werden auf die nächst höhere 2er Potenz gerundet
read -p "Geben Sie die Größe des Speicherplatzes ein: " speicherplatz

speicherplatzInPotenz=$(calculateNextHigherPowerOfTwo $speicherplatz)

if ! is_integer "$speicherplatz"; then
    echo "Error: Speicherplatz muss eine ganze Zahl (Integer) sein."
    exit 1
fi

if [[ "$speicherverwaltung" == "static" ]]; then
read -p "Geben sie die Größe der einzelnen Partitionen ein: " partition

if ! is_integer "$partition"; then
    echo "Error: Die Partitionsgröße muss eine ganze Zahl (Integer) sein."
    exit 1
fi

partitionsgroeseInpotenz=$(calculateNextHigherPowerOfTwo $partition)

#Die Anzahl der Partitionen wir hier ausgrechnet, indem wir den gesamten Speicher (in Zweierpotenz) durch die partitionsgröße (in Zweierpotenz) teilen
matrixLaenge=$(expr $speicherplatzInPotenz / $partitionsgroeseInpotenz)
fi

if [[ $speicherverwaltung == "dynamic" ]];then
    matrixLaenge=$speicherplatzInPotenz
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
readFile

#Mit Hilfe einer for-Schelife wird die Matrix am Ende ausgegeben
for ((i=1; i<=matrixLaenge; i++)); do
    for ((j=1; j<=2; j++)); do
        echo -n "${matrix[$i,$j]}"
    done
    echo
done
