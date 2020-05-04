$window    = $ window
$document  = $ document
$input     = $ "#input"
$output    = $ "#output"
#$outputVal = $output.val

#output     = document.getElementById "output"

# autofocus textarea
$input.focus()
#$input.setSelectionRange 4, 4

# set editor stuff
tmpOutputVal = ""
document.ed = ed =
    init: ->
        @in = ace.edit("input");
        @in.setTheme("ace/theme/monokai");
        @in.session.setMode("ace/mode/coffee");
        @in.setShowPrintMargin(false);

        @out = ace.edit("output");
        @out.setTheme("ace/theme/monokai");
        @out.session.setMode("ace/mode/coffee");
        @out.setShowPrintMargin(false);

        # storage for last input to reload
        if !localStorage.lastInput?
            localStorage["lastInput"] = ""
        else
            ed.setIn localStorage["lastInput"]
            @last = localStorage["lastInput"]
    getIn: ->
        @in.getValue()
    setIn: (_val) ->
        @in.setValue(_val)
    saveIn: ->
        if @last is ed.getIn()
            return
        @last = ed.getIn()
        localStorage["lastInput"] = ed.getIn().trim()


    getOut: ->
        @out.getValue()
    setOut: (_val) ->
        @out.setValue(_val)
        #@out.selection.selectFileStart()
        @out.selection.moveCursorFileEnd()
        @out.selection.selectLine()

    resize: ->
        @out.resize()
        @in.resize()
ed.init()

# main scope
document.scal = scal =
	# TODO: make value check to print "undefined" if no value is present
	#one_value_check: (_val) ->
	#	if _val is undefined
	#		"undefined"
	#	else
	#		_val
    echo: ( val ) ->
        if val is undefined
            #output.value += "undefined\n"
            tmpOutputVal += "undefined\n"
        else
            arr = []
            for val, key in arguments
                arr.push val
            #output.value += arr.join(", ") + "\n"
            tmpOutputVal += arr.join(", ") + "\n"
            #if val2?
            #    output.value += val + ": " + val2 + "\n"
            #else
            #    output.value += val + "\n"
        return
    help: ->
        scal.echo "------------------------- H E L P -------------------------"
        scal.echo "Hello. This is a placeholder for the actual help." 
        scal.echo "Here's a list of some of the available functions and"
        scal.echo "constants:"
        scal.echo "abs, acos, acosh, asin, asinh, atan, atan2, atanh, bignum,"
        scal.echo "cbrt, ceil, clz32, cos, cosh, deriv, E, echo, eecho, exp,"
        scal.echo "expm1, fact, floor, floorLog10x, fround, hist, hypot, imul,",
        scal.echo "lnbr, log, log10, log1p, log2, max, min, necho, necho_nums,"
        scal.echo "PI, prod, random, round, scal, sempty, sign, sin, sinh,"
        scal.echo "sqrt, sum, tan, tanh, trunc."
    lnbr: -> scal.echo "-------------------------"
    reset: ->
        #output.value = ""
        tmpOutputVal = ""
        return
    hist: ->
        data = JSON.parse( localStorage["entries"] )
        for el in data
            scal.echo "\n\n------------------------------"
            scal.echo new Date el.time
            scal.echo el.content
        return
    fact: (n) ->
        if n is 0
            return 1
        else
            a = 1
            a *= x for x in [1..n]
            a
    floorLog10x: (n) ->
        v = Math.floor Math.log10 n
        if v is -Infinity
            0
        else
            v
    sum: (_start, _end, _func, _step = 1) =>
        if Array.isArray _start
            _start.reduce (a, b) => a + b
        else
            res = 0
            res += _func n for n in [_start.._end] by _step
            res
    prod: (_start, _end, _func, _step = 1) =>
        if Array.isArray _start
            _start.reduce (a, b) => a * b
        else
            res = 1
            res = res * _func n for n in [_start.._end] by _step
            res
    deriv: (_func, _x="x") =>
        _func = _func.toString()
        _func = _func.replace /function.*{(?:\n*\s*)*return\s*(.*\n*);(?:\n*\s*)*\}/g, "$1" # extract function
        _func = _func.replace /\(\s*.*\s*\)\s*=>\s*\{\s*return\s*(.*\n*)*\s*;\s*}/g, "$1"   # extract function alternative
        _func = _func.replace /\*\*/g, "^"           # ** needs to be ^
        _func = math.derivative _func, _x            # get derivative
        _func = _func.toString()                     # stringify
        eval "(" + _x + ") => { return " + _func + "; }"
    sempty: "                                                                " # an string with spaces for formatting reasons
    necho_nums: [0,1,2,3,4,5,6,7,8,9,10,12,18,27,40,60,91,137,206,311,469,706,1064,1604,2416,3641,5486,8267,12457,18770,28283,42617,64216,96761,145801,219696,331042,498820,751630,1132570,1706577,2571500,3874782,5838591,8797692,13256519,19975159,30098925,45353595,68339603,102975330,155165058,233805469,352302239,530855280,799902177,1205306827,1816177764,2736648956,4123631318,6213561009,9362704238,14107889262,21258018451,32031960278,48266327439,72728560607,109588688608,165130185041,248821099679,374928058308,564948266396,851274095474,1282714947067,1932817695470,2912404078915,4388462263545,6612612988006,9964002856395,15013936714932,22623266866618,34089140871975,51366123745109,77399388811438,116626775617939,175735299721476,264801075092459,399006969466320,601230797975835,905945259347578,1365094429123612,53816502895996590,878416384462359600,9223372036854775807]
    eecho: (_f) ->
        throw new Error("Function eecho needs a function to be run") if typeof _f isnt "function"
        scal.echo scal.sempty[1..19-scal.floorLog10x x] + x, _f x for x in scal.necho_nums
    
    necho: (_n, _f) ->
        if typeof _n is "function"
            _f = _n
            _n = 50
        max = scal.floorLog10x _n
        scal.echo scal.sempty[1..max-scal.floorLog10x x] + x, _f x for x in [0.._n]
    # actual calculation method, which is run to create the output
    calculate: ->
        start = (new Date()).getTime()
        scal.reset()
        try
            #CoffeeScript.eval pre + "\n" + $input.val()
            CoffeeScript.eval pre + "\n" + ed.getIn()
        catch e
            #$output.val "ERROR: " + e.message
            tmpOutputVal += "ERROR: " + e.message + "\n"
            console.error e
        #$output.val "Total time taken: " + ((new Date()).getTime() - start) + "ms\n" + $output.val()
        ed.setOut tmpOutputVal + "Total time taken: " + ((new Date()).getTime() - start) + "ms\n"



# scoping for the executed browser scripts
pre = """
scal = document.scal

hist = scal.hist

necho_nums = scal.necho_nums

help = scal.help
echo = scal.echo
lnbr = scal.lnbr

# scal math
fact   = scal.fact
sempty = scal.sempty


floorLog10x = scal.floorLog10x

eecho = scal.eecho
necho = scal.necho



# Math.
abs    = Math.abs
acos   = Math.acos
acosh  = Math.acosh
asin   = Math.asin
asinh  = Math.asinh
atan   = Math.atan
atan2  = Math.atan2
atanh  = Math.atanh
cbrt   = Math.cbrt
ceil   = Math.ceil
clz32  = Math.clz32
cos    = Math.cos
cosh   = Math.cosh
exp    = Math.exp
expm1  = Math.expm1
floor  = Math.floor
fround = Math.fround
hypot  = Math.hypot
imul   = Math.imul
log    = Math.log
log1p  = Math.log1p
log2   = Math.log2
log10  = Math.log10
max    = Math.max
min    = Math.min
random = Math.random
round  = Math.round
sign   = Math.sign
sin    = Math.sin
sinh   = Math.sinh
sqrt   = Math.sqrt
tan    = Math.tan
tanh   = Math.tanh
trunc  = Math.trunc

PI  = Math.PI
E   = Math.E

bignum = window.math.bignumber

prod  = scal.prod
sum   = scal.sum
deriv = scal.deriv
"""



ctrlIsDown = false
$input.on "keydown", (e) ->
    if e.keyCode is 17
        ctrlIsDown = true 
    else if e.keyCode is 13 and ctrlIsDown
        scal.calculate()
    ###else if e.keyCode is 9 # tab adds 4 spaces
        e.preventDefault()
        start = input.selectionStart
        val = input.value
        input.value = val.substr(0, start) + "    " + val.substr(start, val.length)
        input.selectionStart = input.selectionEnd = start + 4;
    ###
    return null

$input.on "keyup", (e) ->
    ctrlIsDown = false if e.keyCode is 17
    ed.saveIn()




# create storage for backups
if !localStorage.entries?
    localStorage["entries"] = JSON.stringify []


# saving data, when exiting scal
$window.on "unload", ->
    if $input.val().trim() is "hist()"
        return
    if $input.val().trim() is ""
        return
    data = JSON.parse( localStorage["entries"] )
    #if $input.val().trim() is data[-1].trim()
    #    return
    data.push {
        time: new Date()
        #content: $input.val()
        content: ed.getVal()
    }
    while data.length > 20
        data.shift()
    localStorage["entries"] = JSON.stringify data
    return




#resizing
$window.on "resize", (e) ->
    width  = Math.floor window.innerWidth/2 -4
    height = window.innerHeight - 10
    $input.width  width
    $output.width width
    $input.height  height
    $output.height height
    ed.resize()
    return

$window.resize()
