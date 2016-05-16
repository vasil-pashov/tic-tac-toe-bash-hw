check_row() {
    #1 row; 2 mark; 3 board
    local win=1
    for i in $(seq 1 3);do
        f=$(get $1 $i "$3")
        if [ "$f" != $2 ];then
            win=0
            break
        fi
    done
    echo $win
}

check_col() {
    #1 col; 2 mark; 3 board
    local win=1
    for i in $(seq 1 3);do
        f=$(get $i $1 "$3")
        if [ "$f" != $2 ];then
            win=0
            break
        fi
    done
    echo $win
}

check_main_diag() {
    #1 row; 2 col; 3 mark; 4 board
    local i
    local win=1
    if [ $1 -ne $2 ];then
        win=0
    else
        for i in $(seq 1 3);do
            field=$(get $i $i "$4")
            if [ "$field" != $3 ];then
                win=0
                break
            fi
        done
    fi
    echo "$win"
}

check_sec_diag() {
    #1 row; 2 col; 3 mark; 4 board
    local win=1
    if [ $(( $col + $row )) -ne 4 ];then
        win=0
    else
    for i in $(seq 1 3);do
        field=$(get $(( 4 - $i  )) $i "$4")
            if [ "$field" != $3 ];then
                win=0
                break
            fi
        done

    fi
    echo "$win"
}

check_diags() {
    #1 row; 2 col; 3 mark; 4 board
    main=$(check_main_diag $1 $2 $3 "$4")
    sec=$(check_sec_diag $1 $2 $3 "$4")
    echo $(($main || $sec))
}

check_win() {
    #1 row; 2 col; 3 mark; 4 board
    winRow=$(check_row $1 $3 "$4")
    winCol=$(check_col $2 $3 "$4")
    winDiag=$(check_diags $1 $2 $3 "$4")
    echo $(($winRow || $winCol || $winDiag))
}

put_mark() {
    #1 row; 2 col; 3 mark; 4 board
    pos=$(( ($1 - 1) * 3 + $2 + 1))
    prev=$(echo "$board" |cut -d"|" -f1-$(( $pos - 1)))
    next=$(echo "$board" |cut -d"|" -f$(( $pos + 1))-)
    #echo "$board"
    echo "$prev|$mark|$next"
}

get() {
    #1 row; 2 col;3 board
    echo "$3" >> f
    p=$(( ($1 - 1) * 3 + $2 + 1))
    echo "$3"| cut -d"|" -f$p
}

is_full() {
    #1 board
    f=$(grep "\|[XO]\|[XO]\|[XO]\|" $1 | wc -l) 
    if [ $f -eq 3 ];then
        echo 1
    else
        echo 0
    fi
}

is_free() {
    #1 row; 2 col; 3 board
    field=$(get $1 $2 "$board")
    if [ "$field" = " " ];then
        echo 1
    else
        echo 0
    fi
}

max() {
    if [ $1 -gt $2 ];then
        echo $1
    else
        echo $2
    fi
}

min() {
    if [ $1 -lt $2 ];then
        echo $1
    else
        echo $2
    fi
}
cnt=0
ai() {
    #1 board; 2 mark
    local i
    local j
    for i in $(seq 0 2);do
        for j in $(seq 0 2);do
            if [ $(is_free $i $j $1) -eq 1 ];then
                #cnt=$(( $cnt + 1))
                #echo "$cnt"
                if [ $(check_win $i $j "X" $1) -eq 1 ];then
                    echo -1
                elif [  $(check_win $i $j "O" $1) -eq 1 ];then
                    echo 1
                elif [ $(is_full $1) -eq 1 ];then
                    echo 0
                else
                    f=$(put_mark $i $j $2 $1)
                    if [ $2 = "X" ];then
                        a=$(ai $1 "O" $i $j)
                    else
                        a=$(ai $1 "X" $i $j)
                    fi
                    echo "$i $j" >> f
                    f=$(put_mark $i $j " " $1)
                fi
            fi
        done
    done
}

draw() {
    echo "-------------"
    for i in $(seq 1 3);do
        for j in $(seq 1 3);do
            f=$(get $i $j "$1")
            echo -n "| $f "
        done
        echo "|"
        echo "-------------"
    done
}

#===========Create Dir================
if ! [ -d .tic-tac-toe ];then
    mkdir .tic-tac-toe
fi
#====================================
#=======Enter player Names===========
echo "Enter player one name - X"
read player1

echo "Enter player two name - O"
read player2

echo "$player1 vs. $player2"
#====================================
#=========Log file===================
name="$player1-$player2-$(date +%s)"
filepath=".tic-tac-toe/$name.log"
touch $filepath
#====================================
#========Board file==================

for i in $(seq 0 9);do
    board=$(echo -n "$board |")
done
echo $board

#=====================================================================
#====================Moves=============================================
movesCnt=0
player=$player1
mark="X"
playerFlag=0
while [ $movesCnt -lt 9 ]
do
    #=========================PLAYER 1==================================================
    #=================Player1 validation===============================
    isPositionValid=0
    while [ $isPositionValid -ne 1 ];do
        echo "$player make your move - (row,col)"
        read playerMove
        isPositionValid=$(echo $playerMove | grep "([1-3],[1-3])" | wc -l) 
        if [ $isPositionValid -eq 1 ];then
            row=$(expr substr $playerMove 2 1)
            col=$(expr substr $playerMove 4 1)
            if [ $(is_free $row $col "$board") -eq 0 ];then
                echo "This field is already taken!"
                isPositionValid=0
            fi
        else
            echo "Wrong input!"
        fi
    done
    #==================================================================
    #========================Create new board==========================

   
    board=$(put_mark $row $col $mark $board) 

    echo $board

    draw "$board"

    echo "$player - $playerMove">>$filepath
    if [ $(check_win $row $col $mark "$board") -eq 1 ];then
        echo "$player wins" | tee -a $filepath
        break
    fi

    playerFlag=$(( $playerFlag ^ 1))
    if [ $playerFlag -eq 0 ];then
        player=$player1
        mark="X"
    else
        player=$player2
        mark="O"
        #ai $board $mark
    fi
    movesCnt=$(($movesCnt + 1))
done

if [ $movesCnt -eq 9 ];then
    echo "Even" >> $filepath
fi

