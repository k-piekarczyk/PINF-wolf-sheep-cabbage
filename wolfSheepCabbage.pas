program WolfSheepCabbage;

uses  
    SysUtils, Crt;

type
    bank = (BLeft, BRight);
    eval = (EDone, ELegal, EIllegal);
    movable = (MWolf, MSheep, MCabbage, MFarmer);

    state = record
        wolf, sheep, cabbage, farmer: bank;
    end;

    moveptr = ^move;
    move = record
        orig, dest: bank;
        moved: movable;
        next: moveptr;
    end;

    stackptr = ^stack;
    stack = record
        gameState: state;
        next: stackptr;
    end;

    { Helper functions }

    function oppositeBank(b: bank) : bank;
    begin
        if (b = BRight) then
            oppositeBank := BLeft
        else
            oppositeBank := BRight;
    end;

    { Stringifying functions }

    function bank2str(s: state; b: bank) : string;
    begin
        bank2str := '';

        if (s.wolf = b) then
            bank2str := bank2str + 'W';

        if (s.sheep = b) then
            bank2str := bank2str + 'O';

        if (s.cabbage = b) then
            bank2str := bank2str + 'K';

        if (s.farmer = b) then
            bank2str := bank2str + 'F';
    end;

    function state2str(s: state) : string;
    begin
        state2str := '[ ' + bank2str(s, BLeft) + ' || ' + bank2str(s, BRight) + ' ]'; 
    end;

    function stack2str(stk: stackptr) : string;
    begin
        stack2str := state2str(stk^.gameState);

        while (stk^.next <> nil) do
        begin
            stk := stk^.next;
            stack2str := stack2str + ' -> ' + state2str(stk^.gameState);
        end;
    end;

    { Stack manipulation }

    function appendState(stk: stackptr; s: state) : stackptr;
    var
        stkptr: stackptr;
    begin
        appendState := stk;
        if (appendState = nil) then
        begin
            new(appendState);
            stkptr := appendState;
        end
        else
        begin
            stkptr := appendState;
            while(stkptr^.next <> nil) do
                stkptr := stkptr^.next;
            new(stkptr^.next);
            stkptr := stkptr^.next;
        end;
        stkptr^.next := nil;
        stkptr^.gameState := s;
end;

function popState(stk: stackptr) : stackptr;
begin
    popState := stk;
    if ((stk <> nil) and (stk^.next = nil)) then
    begin
        dispose(stk);
        popState := nil;
    end
    else
    begin
        while((stk^.next <> nil) and (stk^.next^.next <> nil)) do
            stk := stk^.next;
		
		dispose(stk^.next);
        stk^.next := nil;
    end;
end;

procedure tearDownStack(stk: stackptr);
begin
    if (stk <> nil) then
    begin
        if (stk^.next <> nil) then
            tearDownStack(stk^.next);
        dispose(stk);
    end;
end;

{ Move list manipulation }

function appendMove(list: moveptr; origin, destination: bank; moved: movable ) : moveptr;
var 
    mvptr: moveptr;
begin
        appendMove := list;
        if (appendMove = nil) then
        begin
            new(appendMove);
            mvptr := appendMove;
        end
        else
        begin
            mvptr := appendMove;
            while(mvptr^.next <> nil) do
                mvptr := mvptr^.next;
            new(mvptr^.next);
            mvptr := mvptr^.next;
        end;
        mvptr^.next := nil;
        mvptr^.dest := destination;
        mvptr^.orig := origin;
		mvptr^.moved := moved;
end;

procedure tearDownMoveList(list: moveptr);
begin
    if (list <> nil) then
    begin
        if (list^.next <> nil) then
            tearDownMoveList(list^.next);
        dispose(list);
    end;
end;

{ Problem definition }

function stateEval(s: state) : eval;
begin
    stateEval := ELegal;
    if (((s.wolf = s.sheep) and (s.wolf <> s.farmer)) or ((s.sheep = s.cabbage) and (s.sheep <> s.farmer))) then
        stateEval := EIllegal;
    
    if ((s.wolf = BRight) and (s.sheep = BRight) and (s.cabbage = BRight) and (s.farmer = BRight)) then
        stateEval := EDone;
end;

function genStates(s: state) : moveptr;
begin
    genStates := nil;
    genStates := appendMove(genStates, s.farmer, oppositeBank(s.farmer), MFarmer);

    if (s.wolf = s.farmer) then
        genStates := appendMove(genStates, s.wolf, oppositeBank(s.wolf), MWolf);
    
    if (s.sheep = s.farmer) then
        genStates := appendMove(genStates, s.sheep, oppositeBank(s.sheep), MSheep);
    
    if (s.cabbage = s.farmer) then
        genStates := appendMove(genStates, s.cabbage, oppositeBank(s.cabbage), MCabbage);
end;

function search(s: state; depth: byte; stk: stackptr; showFailed: boolean) : eval;
var
    mvptr, x: moveptr;
    nextState: state;
    ev: eval;
begin
    search := stateEval(s);

    if (search = EDone) then
    begin
        TextColor(Green);
        write('+ :do dna ', depth, ':  ', stack2str(stk));
        TextColor(White);
        write(#10);
    end 
    else
    if((depth > 0) and (search <> EIllegal)) then
    begin
        mvptr := genStates(s);
        x := mvptr;

        while (mvptr <> nil) do
        begin
            nextState := s;
            nextState.farmer := oppositeBank(nextState.farmer);

            if (mvptr^.moved = MWolf) then
                nextState.wolf := oppositeBank(nextState.wolf)
            else if (mvptr^.moved = MSheep) then
                nextState.sheep := oppositeBank(nextState.sheep)
            else if (mvptr^.moved = MCabbage) then
                nextState.cabbage := oppositeBank(nextState.cabbage);

            stk := appendState(stk, nextState);
            ev := search(nextState, depth - 1, stk, showFailed);

            if (search <> EDone) then
            begin
                if (ev = EDone) then
                    search := EDone
                else if ((ev = ELegal) and (search = EIllegal)) then
                    search := ELegal;
            end;

            if (showFailed and (search = ELegal)) then
            begin
                TextColor(DarkGray);
                write('- :do dna ', depth, ':  ', stack2str(stk));
                TextColor(White);
                write(#10);
            end;

            stk := popState(stk);
            mvptr := mvptr^.next;
        end;

        tearDownMoveList(x);
    end;
end;

function searchSolution(s: state; depth: byte; showFailed: boolean) : eval;
var
    stk: stackptr;
begin
    stk := appendState(nil, s);
    searchSolution := search(s, depth, stk, showFailed);
    tearDownStack(stk);    
end;

{ Main }
var
    depth, argumentOffset: byte;
    showFailed: boolean;
    s: state;
    ev: eval;

begin
    depth := 7;
    argumentOffset := 0;
    showFailed := true;

    if ((ParamCount <> 0) and (ParamCount <> 2) and (ParamCount <> 4)) then
    begin
        writeln('Dostepne opcje:');
        writeln(#9'-h {"true", "false"}: ukryj nieudane przejscia');
        writeln(#9'-d <byte>: glebokosc poszukiwania rozwiazania');
        exit;
    end;

    while (argumentOffset <> ParamCount) do
    begin
        if ((ParamStr(argumentOffset+1) = '-h') and (ParamStr(argumentOffset+2) = 'true')) then
            showFailed := false;
        if (ParamStr(argumentOffset+1) = '-d') then
            depth := StrToInt(ParamStr(argumentOffset+2));
        
        argumentOffset := argumentOffset + 2;
    end;


    writeln('Poszukuje rozwiazania z glebokoscia przeszukiwania ', depth);

    s.wolf := BLeft;
    s.sheep := BLeft;
    s.cabbage := BLeft;
    s.farmer := BLeft;

    ev := searchSolution(s, depth, showFailed);

    write('Wynik: ');
    if (ev = EDone) then
    begin
        TextColor(Green);
        write('znaleziono rozwiazania!');
        TextColor(White);
    end else
    begin
        TextColor(Red);
        write('nie znaleziono rozwiazan...');
        TextColor(White);
    end;
    write(#10);
end.
