@set @junk=1 /* vim:set ft=javascript:
@echo off
cscript //nologo //e:jscript "%~dpn0.bat" %*
goto :eof
*/
//
// Global variables
//
var stdin = WScript.StdIn;
var stdout = WScript.StdOut;
var stderr = WScript.StdErr;

var About = {
	name : "WGETS",
	version : "1.1",
	majorVersion : 1,
	minorVersion : 1,
	copyright : "Copyright (c) Atif Aziz. All rights reserved.",
	authors : [{
			name : "Atif Aziz",
			href : "http://www.raboof.com/"
		}
	],
	description : "A non-interactive web retriever script.",
	license : {
		title : "Creative Commons Attribution-ShareAlike 3.0 Unported License.",
		href : "http://creativecommons.org/licenses/by-sa/3.0/"
	},
	write : function (writeln) {
		writeln(this.name + ' ' + this.version + ' - ' + this.description);
		writeln(this.copyright);
		writeln();
		if (this.authors.length) {
			var author = function () {
				return this.name + ', ' + this.href;
			};
			if (this.authors.length > 1) {
				writeln('Written by:');
				for (var i = 0; i < this.authors.length; i++)
					writeln('- ' + author.apply(this.authors[i]));
			} else {
				writeln('Written by ' + author.apply(this.authors[0]));
			}
			writeln();
		}
		writeln(this.license.title);
		writeln(' ' + this.license.href);
		writeln();
	}
}

//
// Global functions
//

function writeln(s) {
	stdout.WriteLine(s);
}
function write(s) {
	stdout.Write(s);
}
function alert(s) {
	echo(s);
}
function echo(s) {
	WScript.Echo(s);
}

//
// ADO Constants
//

var ADO = {
	SaveOptionsEnum : {
		adSaveCreateNotExist : 1,
		adSaveCreateOverWrite : 2
	},
	StreamTypeEnum : {
		adTypeBinary : 1,
		adTypeText : 2
	}
};

//
// Mask
//

var Mask = {
	nullString : function (s) {
		return s == null ? "" : s;
	},
	emptyString : function (s, mask) {
		return s == null || s.length == 0 ? mask : s;
	},
	nullObject : function (o, mask) {
		return o == null ? mask : o;
	}
};

//
// Path
//

var Path = {
	combine : function (path1, path2) {
		path1 = Mask.nullString(path1);
		path2 = Mask.nullString(path2);
		
		var sb = [];
		sb.push(path1);
		if (path1.slice(-1) != "\\")
			sb.push("\\");
		sb.push(path2.indexOf("\\") == 0 ? path2.substring(1) : path2);
		return sb.join("");
	}
};

//
// Test
//

var Test = {
	assertEquals : function (expected, actual, message) {
		if (actual != expected)
			throw new Exception("Equality assertion test failed. " + Mask.nullString(message));
	}
};

//
// Reflection
//

var Reflection = {
	getFunctionName : function (f) {
		var match = f.toString().match(/function\s+(\w*)/);
		return match == null ? "(anonymous)" : match[1];
	}
};

//
// Diagnostics
//

var Diagnostics = {
	trace : function (s) {
		echo("TRACE: " + s);
	},
	here : function () {
		this.trace("I am here!");
	},
	stackTrace : function () {
		var trace = "";
		
		for (var aCaller = arguments.caller; aCaller != null; aCaller = aCaller.caller) {
			trace += "-> " + Reflection.getFunctionName(aCaller.callee) + "\n";
			
			if (aCaller.caller == aCaller) {
				trace += "*";
				break;
			}
		}
		
		return trace;
	}
};

//
// HTTP
//

var HTTP = {
	getResponseHeaders : function (http) {
		var headersText = http.getAllResponseHeaders();
		
		var parser = /^([^\:\r]+)\:\s*(.+)$/gm;
		var match;
		var headers = {};
		while ((match = parser.exec(headersText)) != null) {
			var name = match[1].trim().toLowerCase();
			var value = match[2].trim();
			headers[name] = value;
		}
		
		return headers;
	}
};

//
// String (extensions)
//

String.prototype.mask = function (mask) {
	return Mask.emptyString(this, mask);
}

String.prototype.trim = function () {
	return this.replace(/^[\s]+/, "").replace(/[\s]+$/, "");
}

String.prototype.clipLeft = function (width, decoration) {
	decoration = Mask.emptyString(decoration, "...");
	
	if (this.length <= width)
		return this;
	
	return decoration + this.slice(-width);
}

//
// Exception
//

function Exception(message) {
	this.init(message);
}

Exception.prototype.init = function (message) {
	this.message = Mask.emptyString(message, "A general error has occurred.");
	this.stackTrace = Diagnostics.stackTrace();
}

Exception.prototype.toString = function () {
	return this.message;
}

//
// ProgramArgumentException extends Exception
//

ProgramArgumentException.prototype = new Exception();
ProgramArgumentException.prototype.constructor = ProgramArgumentException;
ProgramArgumentException.base = Exception.prototype;

function ProgramArgumentException(message) {
	message = Mask.emptyString(message, "Error with program argument.") +
		" Use the /? for help.";
	
	ProgramArgumentException.base.init.call(this, message);
}

try {
	var wshargs = WScript.Arguments;
	var args = [];
	for (var i = 0; i < wshargs.length; i++)
		args.push(wshargs(i));
	
	args.unnamed = [];
	
	for (var i = 0; i < wshargs.Unnamed.Count; i++)
		args.unnamed.push(wshargs.Unnamed.Item(i));
	
	args.getNamed = function (name) {
		return WScript.Arguments.Named.Item(name);
	}
	args.isFlagged = function (name) {
		return WScript.Arguments.Named.Exists(name);
	}
	
	if (args.isFlagged("test"))
		test();
	else
		main(args);
} catch (e) {
	stderr.WriteLine(e.message == null ? e.toString() : e.message);
	WScript.Quit(-1);
}

function main(args) {
	var logo = args.isFlagged('logo');
	if (logo)
		About.write(function (s) {
			stderr.WriteLine(s);
		});
	
	if (args.unnamed.length == 0) {
		if (logo)
			return;
		throw new ProgramArgumentException("Missing URL.");
	}
	
	var outputFileName,
	url = args.unnamed[0],
	useStandardOutput = false,
	httpStatusOnly = args.isFlagged("status"),
	httpHeadersOnly = args.isFlagged("headers"),
	dontOutputEntity = httpStatusOnly || httpHeadersOnly;
	
	if (!dontOutputEntity) {
		if (args.unnamed.length > 1) {
			outputFileName = args.unnamed[1];
			useStandardOutput = outputFileName == "-";
		} else {
			outputFileName = getFileNameFromURL(url, "");
			
			if (outputFileName.length == 0)
				throw new Exception("Unable to guess the output file name from the URL.");
		}
	}
	
	var http = new ActiveXObject("Microsoft.XMLHTTP");
	http.open(dontOutputEntity ? "HEAD" : "GET", url, false);
	http.send();
	
	var httpStatus = http.status + " " + http.statusText;
	
	if (httpStatusOnly)
		writeln(httpStatus);
	if (httpHeadersOnly)
		write(http.getAllResponseHeaders());
	
	if (dontOutputEntity)
		return;
	
	var headers = HTTP.getResponseHeaders(http);
	var contentLength = parseInt(Mask.nullObject(headers["content-length"], -1));
	
	var outputDirectory = Mask.nullString(args.getNamed("od"));
	var outputPath = outputDirectory.length > 0 ?
		Path.combine(outputDirectory, outputFileName) : outputFileName;
	
	if (http.status != 200)
		throw new Exception(httpStatus);
	
	if (useStandardOutput) {
		write(http.responseText);
	} else {
		var stream = new ActiveXObject("ADODB.Stream");
		stream.Type = ADO.StreamTypeEnum.adTypeBinary;
		stream.Open();
		stream.Write(http.responseBody);
		stream.SaveToFile(outputPath, ADO.SaveOptionsEnum.adSaveCreateOverWrite);
		
		write("Saved " + url.clipLeft(30) + " to " + outputPath);
		if (contentLength >= 0)
			write(" [" + contentLength + " byte(s)]");
		writeln(".");
	}
}

function getFileNameFromURL(url, defaultFileName) {
	var qIndex = url.indexOf('?');
	
	var path = qIndex >= 0 ? url.substring(0, qIndex) : url;
	
	var lastSlashIndex = path.lastIndexOf('/');
	var result = path.substring(lastSlashIndex + 1);
	
	return result.length > 0 ? result : defaultFileName;
}

function getScriptNameFromHost() {
	var name = WScript.ScriptName;
	var dotIndex = name.lastIndexOf('.');
	return dotIndex >= 0 ? name = name.substring(0, dotIndex) : name;
}

function test() {}
