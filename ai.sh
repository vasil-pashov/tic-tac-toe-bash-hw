check_row() {
    #1 row; 2 mark; 3 board
    local win=1
    for i in $(seq 1 3);do
        local f=$(get $1 $i "$3")
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
        local f=$(get $i $1 "$3")
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
    if [ $(( $1 + $2 )) -ne 4 ];then
        win=0
    else
    for i in $(seq 1 3);do
        local field=$(get $(( 4 - $i  )) $i "$4")
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
    echo "$1 $2" >> file
    #1 row; 2 col; 3 mark; 4 board
    winRow=$(check_row $1 $3 "$4")
    winCol=$(check_col $2 $3 "$4")
    winDiag=$(check_diags $1 $2 $3 "$4")
    echo $(($winRow || $winCol || $winDiag))
}

put_mark() {
    #1 row; 2 col; 3 mark; 4 board
    pos=$(( ($1 - 1) * 3 + $2 + 1))
    prev=$(echo "$4" |cut -d":" -f1-$(( $pos - 1)))
    next=$(echo "$4" |cut -d":" -f$(( $pos + 1))-)
    echo "$prev:$3:$next"
}

get() {
    #1 row; 2 col;3 board
    p=$(( ($1 - 1) * 3 + $2 + 1))
    res=$(echo "$3"| cut -d":" -f$p)
    echo "$res"
}

is_full() {
    #1 board
    f=$(echo "$1" | grep -o "[XO]"| wc -l) 
    if [ $f -eq 9 ];then
        echo 1
    else
        echo 0
    fi
}

is_free() {
    #1 row; 2 col; 3 board
    field=$(get $1 $2 "$3")
    if [ "$field" = "X" ] || [ "$field" = "O" ];then
        #echo "$field = X || $field = O"
        echo 0
    else
        #echo "$field != X && $field != O"
        echo 1
    fi
}
draw() {
    echo "-------------"
    local i
    for i in $(seq 1 3);do
        for j in $(seq 1 3);do
            f=$(get $i $j "$1")
            if [ -z $f ];then
                echo -n "|   "
            else
                echo -n "| $f "
            fi
        done
        echo "|"
        echo "-------------"
    done
}

max() {
    if ! [ -z $2 ] && [ $1 -gt $2 ];then
        echo $1
    else
        echo "$3 $4" > file
        echo $2
    fi
}

min() {
    if ! [ -z $2 ] && [ $1 -lt $2 ];then
        echo $1
    else
        echo "$3 $4" > file
        echo $2
    fi
}

b="$1"
r="$3"
c="$4"
#draw "$b"
#echo $(is_full $1)

if [ $2 = "X" ];then
    result=2
else
    result=-2
fi

if [ $(check_win $3 $4 "O" $1) -eq 1 ];then
    echo 1
elif [ $(check_win $3 $4 "X" $4) -eq 1 ];then
    echo -1
elif [ $(is_full $1) -eq 1 ];then
    echo 0
else
    for i in $(seq 1 3);do
        for j in $(seq 1 3);do
            if [ $(is_free $i $j "$b") -eq 1 ];then
                new=$(put_mark $i $j "$2" "$b")
                if [ $2 = "X" ];then
                    newM="O"
                else
                    newM="X"
                fi
                #bash ai.sh $new $newM $i $j
                res=$(bash ai.sh $new $newM $i $j)
                #echo $res
                if ! [ -z "$res" ];then
                if [ $2 = "X" ];then
                    result=$(min $result $res $3 $4)
                    #echo "$result X" >> f
                else
                    result=$(max $result $res $3 $4)
                    #echo "$result O" >> f
                fi
            fi
            fi
        done
    done
fi
