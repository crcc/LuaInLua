local lex = require 'parsing.lex'
local re = require 'parsing.re'

--[[--
// Character classes of tokens
%production Name "class of valid identifiers"
%production String "class of valid strings"
%production Number "class of valid numbers"

%production FUNCTION
%production EQ
%production COMMA
%production QUAD
%production PERIOD
%production LPAREN
%production RPAREN
%production END
%production SEMICOLON
%production LBRACE
%production RBRACE
%production OR
%production AND
%production NOTEQ
%production EQEQ
%production GE
%production GT
%production LE
%production LT
%production CONCAT
%production MOD
%production POW
%production DIV
%production MUL
%production MIN
%production PLUS
%production LBRACK
%production RBRACK
%production LOCAL
%production FOR
%production IF
%production THEN
%production REPEAT
%production UNTIL
%production WHILE
%production DO
%production GOTO
%production BREAK
%production IN
%production RETURN
%production DOTS
%production TRUE
%production FALSE
%production NIL
%production ELSE
%production ELSEIF
%production HASH
%production NOT
%production COLON
--]]--

local longcomment
local longstringprefix
local longstring
local str_prefix
local str

local function id(token) return function(x) return {token, x} end end
local function ignore(...) return end
local function pop(stack) return table.remove(stack) end
local function push(item, stack) table.insert(stack, item) end

return lex.lex {
  root = {
    {'(', id 'LPAREN'},
    {',', id 'COMMA'},
    {':', id 'COLON'},
    {']', id 'RBRACK'},
    {'.', id 'PERIOD'},
    {'~=', id 'NOTEQ'},
    {'==', id 'EQEQ'},
    {'>=', id 'GE'},
    {'>', id 'GT'},
    {'<=', id 'LE'},
    {'<', id 'LT'},
    {'..', id 'CONCAT'},
    {'%', id 'MOD'},
    {'^', id 'POW'},
    {'/', id 'DIV'},
    {'*', id 'MUL'},
    {'+', id 'PLUS'},
    {'=', id 'EQ'},
    {'#', id 'HASH'},
    {')', id 'RPAREN'},
    {';', id 'SEMICOLON'},
    {'...', id 'DOTS'},
    {'{', id 'LBRACE'},
    {'}', id 'RBRACE'},
    {'::', id 'QUAD'},
    {'function', id 'FUNCTION'},
    {'true', id 'TRUE'},
    {'false', id 'FALSE'},
    {'nil', id 'NIL'},
    {'or', id 'OR'},
    {'and', id 'AND'},
    {'return', id 'RETURN'},
    {'local', id 'LOCAL'},
    {'for', id 'FOR'},
    {'in', id 'IN'},
    {'do', id 'DO'},
    {'end', id 'END'},
    {'if', id 'IF'},
    {'not', id 'NOT'},
    {'then', id 'THEN'},
    {'else', id 'ELSE'},
    {'elseif', id 'ELSEIF'},
    {'repeat', id 'REPEAT'},
    {'until', id 'UNTIL'},
    {'while', id 'WHILE'},
    {'goto', id 'GOTO'},
    {'break', id 'BREAK'},
    
    {re '(%a|_)(%a|%d|_)*', id 'IDENTIFIER'},
    {re '%s+', ignore},
    
    {re '--[[', function(_, lexer) lexer:go 'longcomment' end},
    {re '--[=[', function(_, lexer) lexer:go 'longcomment1' end},
    {re '--[==+[', function(piece, lexer) longcomment = piece; lexer:go 'longcommentn' end},
    {re '--[^\n]*', ignore},
    {re '[[', function(_, lexer) longstring = ''; lexer:go 'longstring' end},
    {re '[=[', function(_, lexer) longstring = ''; lexer:go 'longstring1' end},
    {re '[==+[', function(piece, lexer) longstring = ''; longstringprefix = piece; lexer:go 'longstringn' end},
    {re '-', id 'MIN'},
    {re '[', id 'LBRACK'},
    
    {re '"|\'', function(piece, lexer) str_prefix = piece; str = ''; lexer:go 'string' end},
  },
  string = {
    {re '[^\'"\\]+', function(piece) str = str .. piece end},
    {re '\\"|\\\'', function(piece) str = str .. piece:sub(2, 2) end},
    {re '"|\'', 
      function(piece, lexer)
        if piece == str_prefix then
          lexer:go 'root'
          return {'String', str}
        else
          str = str .. piece
        end
      end},
    {re '.', function(piece) str = str .. piece end},
  },
  longcomment = {
    {re '.', ignore},
    {']]', function(_, lexer) lexer:go 'root' end},
  },
  longcomment1 = {
    {re '.', ignore},
    {']=]', function(_, lexer) lexer:go 'root' end},
  },
  longcommentn = {
    {re ']==+]', 
      function(piece, lexer)
        if (2 + #piece) == #longcomment then
          lexer:go 'root'
        end
      end},
    {re '.', ignore},
  },
  longstring = {
    {re '.', function(c) longstring = longstring .. c end},
    {']]', function(_, lexer) lexer:go 'root'; return {'String', longstring} end},
  },
  longstring1 = {
    {re '.', function(c) longstring = longstring .. c end},
    {']=]', function(_, lexer) lexer:go 'root'; return {'String', longstring} end},
  },
  longstringn = {
    {re ']==+]', 
      function(piece, lexer)
        if #piece == #longstringprefix then
          lexer:go 'root'
          return {'String', longstring}
        end
      end},
    {re '.', function(c) longstring = longstring .. c end},
  },
}