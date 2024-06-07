#!/bin/bash
addProzessStatic() {
    echo add
}

removeProzessStatic() {
    echo remove
}

readFile() {
    while IFS= read -r line || [[ -n $line ]]; do
        line=$(echo "$line" | tr -d '\r')
        anweisung=$(echo "$line" | cut -d' ' -f1)
        prozess=$(echo "$line" | cut -d' ' -f2)
        if [[ "$anweisung" == 'add' ]]; then
            addProzessStatic "$prozess"
            elif [[ "$anweisung" == 'remove' ]]; then
            removeProzessStatic "$prozess"
        fi
    done < example.txt
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

#Als erstes wird vom Benutzer die Speicherplatzgröße, sowie die Größe der Partitionen eingelesen
#Beide Werte werden auf die nächst höhere 2er Potenz gerundet
read -p "Geben Sie die Größe des Speicherplatzes ein: " speicherplatz

speicherplatzInPotenz=$(calculateNextHigherPowerOfTwo $speicherplatz)

read -p "Geben sie die Größe der einzelnen Partitionen ein: " partition

partitionsgroeseInpotenz=$(calculateNextHigherPowerOfTwo $partition)

#Die Anzahl der Partitionen wir hier ausgrechnet, indem wir den gesamten Speicher (in Zweierpotenz) durch die partitionsgröße (in Zweierpotenz) teilen
anzahlPartitonen=$(expr $speicherplatzInPotenz / $partitionsgroeseInpotenz)

declare -A matrix

#Hier wird eine zweidimensionale Matrix definiert
#Bei der statischen Partitionierung ist die Länge der Matrix , also die Anzahl der Zeilen), gleich der Anzahl an Partitonen
#In der ersten Spalte wird i als Zähler hochgezählt um auf die Prozesse später zugreifen zu können
#und in der zweiten Spalte speichern wir die zugewiesenen Prozesse
for ((i=1; i<=anzahlPartitonen; i++)); do
    matrix[$i,1]=$i
    matrix[$i,2]=""
done

#In dieser Methode wwerden die Prozesse über eine .txt Datei eingelesen und Prozesse erstellt bzw. terminiert
readFile

#Mit Hilfe einer for-Schelife wird die Matrix am Ende ausgegeben
for ((i=1; i<=anzahlPartitonen; i++)); do
    for ((j=1; j<=2; j++)); do
        echo -n "${matrix[$i,$j]} "
    done
    echo
done

