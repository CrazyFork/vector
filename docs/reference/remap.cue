package metadata

remap: {
	#RemapParameterTypes: "path" | "float" | "integer" | "string" | "timestamp" | "boolean" | "array" | "map" | "regex" | "null"

	#RemapReturnTypes: "float" | "integer" | "string" | "timestamp" | "boolean" | "array" | "map" | "null"

	{
		description: """
			The Timber Remap Language (TRL) is a single-purpose, [Rust](\(urls.rust))-native data
			mapping language that enables you to easily map and reshape data without sacrificing
			performance or safety. It occupies a comfortable middle ground between stringing
			together fundamental [transforms](\(urls.vector_transforms)) and using a full-blown
			runtime like [Lua](\(urls.lua)). Guiding principles behind TRL include:

			1. **Performance** - Beyond extremely fast execution, TRL is designed to prevent
			   Vector operators from writing slow scripts.
			2. **Safety** - TRL is Rust native and performs compile-time checks at boot time to
			   ensure safety. In addition, TRL's simplicity and lack of complex \"footguns\" are
			   ideal for collaboration.
			3. **Easy** - A TRL script's intentions are clear even at first glance because the
			   language is designed to have a very gentle learning curve.

			TRL is designed and maintained by [Timber](\(urls.timber)) and built specifically for
			processing data within Vector.
			"""

		errors: [Name=string]: {
			description: string
			name:        Name
		}

		functions: [Name=string]: {
			#Argument: {
				name:        string
				description: string
				required:    bool
				multiple:    bool | *false
				default?:    bool | string | int
				type: [#RemapParameterTypes, ...#RemapParameterTypes]
			}
			#RemapExample: {
				title: string
				configuration?: [string]: string
				input:  #Fields
				source: string
				output: #Fields
			}

			arguments: [...#Argument] // Allow for empty list
			return: [#RemapReturnTypes, ...#RemapReturnTypes]
			category:    "coerce" | "numeric" | "object" | "parse" | "text" | "hash" | "event" | "networking"
			description: string
			examples: [#RemapExample, ...#RemapExample]
			name: Name
		}
	}

	errors: {
		ArgumentError: {
			description: "Raised when the provided input is not a supported type."
		}
		ParseError: {
			description: "Raised when the provided input cannot be parsed."
		}
	}

	// TRL type system
	types: [TypeName=string]: {
		#Use: "parameter" | "return"

		description: string
		use: [#Use, ...#Use]
		examples: [string, ...string]
	}

	types: {
		"array": {
			description: """
				A list of items. Items in an array can be of any TRL type, including other arrays.

				Array values can be accessed index (starting with zero):

				```
				$levels = ["critical", "emergency", "alert"]
				$levels[0]
				```

				You can also assign values to arrays via index:

				```
				$levels[3] = "not_so_terrible"
				```
				"""
			use: ["parameter", "return"]
			examples: [
				"[200, 201, 202, 204]",
				#"["error", "warn", "emerg"]"#,
				"[[1, 2, 3], [4, 5, 6]]",
				#"[true, 10, {"foo": "bar"}, [10], 47.5]"#,
			]
		}
		"boolean": {
			description: "`true` or `false`."
			use: ["parameter", "return"]
			examples: [
				"true",
				"false",
			]
		}
		"float": {
			description: "A 64-bit floating-point number."
			use: ["parameter", "return"]
			examples: [
				"0.0",
				"47.5",
				"-459.67",
			]
		}
		"map": {
			description: """
				A key-value map in which keys are strings and values can be of any TRL type,
				including nested maps.
				"""
			use: ["parameter", "return"]
			examples: [
				#"{"code": 200, "error_type": "insufficient_resources"}"#,
				"""
					{
					  "user": {
					    "id": "tonydanza1337",
						"pricing_plan": "elite",
						"boss": true
					  }
					}
					""",
			]
		}
		"integer": {
			description: "A 64-bit integer."
			use: ["parameter", "return"]
			examples: [
				"0",
				"1337",
				"-25",
			]
		}
		"null": {
			description: "No value."
			use: ["return"]
			examples: [
				"null",
			]
		}
		"regex": {
			description: """
				A **reg**ular **ex**pression. In TRL, regular expressions are delimited by `/` and
				use [Rust regex syntax](\(urls.rust_regex_syntax)).

				### Flags

				TRL regexes allow three flags:

				Flag | Description
				:----|:-----------
				`g` | Search for *all* matches
				`i` | Case insensitive
				`m` | Multi-line mode

				Regex flags can be combined, as in `/pattern/gmi` or `/pattern/gi`.

				To learn more about regular expressions in Rust—and by extension in TRL—we strongly
				recommend the in-browser [Rustexp expression editor and
				tester](\(urls.regex_tester)).
				"""
			use: ["parameter"]
			examples: [
				#"/^http\://[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$/"#,
				#"""
					$pattern = /(foo|bar)/
					$is_foo_or_bar = match("does contain foo", $pattern)
					"""#,
			]
		}
		"string": {
			description: #"""
				A sequence of characters. A few things to note about TRL strings:

				* Remap converts strings in scripts to [UTF-8](\(urls.utf8)) and replaces any
					invalid sequences with `U+FFFD REPLACEMENT CHARACTER` (�).
				* Strings can be escaped using `\`, as in `The password is \"opensesame\".`.
				* Multi-line strings *are* allowed and don't require any special syntax. See the
					multi-line example below.
				"""#
			use: ["parameter", "return"]
			examples: [
				"\"I am a teapot\"",
				#"""
					"I am split
					across multiple lines"
					"""#,
				#"This is not escaped, \"but this is\""#,
			]
		}
		"timestamp": {
			description: """
				A string formatted as a timestamp. Timestamp specifiers can be either:

				1. One of the built-in-formats listed in the [Timestamp Formats](#timestamp-formats)
					table below, or
				2. Any valid sequence of [time format specifiers](\(urls.chrono_time_formats)) from
					Rust's `chrono` library.

				### Timestamp Formats

				The examples in this table are for 54 seconds after 2:37 am on December 1st, 2020 in
				Pacific Standard Time.

				Format | Description | Example
				:------|:------------|:-------
				`%F %T` | `YYYY-MM-DD HH:MM:SS` | `2020-12-01 02:37:54`
				`%v %T` | `DD-Mmm-YYYY HH:MM:SS` | `01-Dec-2020 02:37:54`
				`%FT%T` | [ISO 8601](\(urls.iso_8601))\\[RFC 3339](\(urls.rfc_3339)) format without time zone | `2020-12-01T02:37:54`
				`%a, %d %b %Y %T` | [RFC 822](\(urls.rfc_822))/[2822](\(urls.rfc_2822)) without time zone | `Tue, 01 Dec 2020 02:37:54`
				`%a %d %b %T %Y` | [`date`](\(urls.date)) command output without time zone | `Tue 01 Dec 02:37:54 2020`
				`%a %b %e %T %Y` | [ctime](\(urls.ctime)) format | `Tue Dec  1 02:37:54 2020`
				`%s` | [UNIX](\(urls.unix_timestamp)) timestamp | `1606790274`
				`%FT%TZ` | [ISO 8601](\(urls.iso_8601))/[RFC 3339](\(urls.rfc_3339)) UTC | `2020-12-01T09:37:54Z`
				`%+` | [ISO 8601](\(urls.iso_8601))/[RFC 3339](\(urls.rfc_3339)) UTC with time zone | `2020-12-01T02:37:54-07:00`
				`%a %d %b %T %Z %Y` | [`date`](\(urls.date)) command output with time zone | `Tue 01 Dec 02:37:54 PST 2020`
				`%a %d %b %T %z %Y`| [`date`](\(urls.date)) command output with numeric time zone | `Tue 01 Dec 02:37:54 -0700 2020`
				`%a %d %b %T %#z %Y` | [`date`](\(urls.date)) command output with numeric time zone (minutes can be missing or present) | `Tue 01 Dec 02:37:54 -07 2020`
				"""
			use: ["parameter", "return"]
			examples: [
				"%a %d %b %T %Y",
				"%FT%TZ",
			]
		}
	}

	// TRL syntax
	#Operators: [_category=string]: [_op=string]: string

	syntax: [RuleName=string]: {
		name:        RuleName
		href:        string // Ensures that we don't end up with clashing anchors
		description: string
		examples: [string, ...string]
		operators?: #Operators
	}

	syntax: {
		"Dot notation": {
			href: "dot-notation"

			description: """
				In TRL, a dot (`.`) holds state across the script. At the beginning of the script,
				it represents the object arriving into the transform. That object can be a
				log or a metric. To give an example, imagine you're writing a TRL script to handle
				logs that are already in [JSON](\(urls.json)) form.

				```json
				{"status_code":200,"username":"booper1234","message":"Successful transaction"}
				```

				In this case, the object, represented by the dot, has three fields: `.status_code`,
				`.username`, and `.message`. You can assign new values to the existing fields
				(`.message = "something different"`), add new fields (`.new_field = "new value"`),
				delete fields (`del(.username)`), store those values in variables (`$code =
				.status_code`), and more.

				The dot can also represent nested values, for example `.transaction.id` or
				`.geo.latitude`.
				"""
			examples: [
				".",
				".status_code",
				".message",
				".username",
				".transaction.id",
				".geo.latitude",
			]
		}

		"Functions": {
			href: "functions"

			description: """
				In TRL, functions can take inputs (or no input) and return a value, `null`, or an
				error.
				"""

			examples: [
				"parse_json(.message)",
				"assert(.status_code == 500)",
				#"ip_subnet(.address, "255.255.255.0")"#,
				".request_id = uuidv4()",
			]
		}

		"Control flow": {
			href: "control-flow"

			description: """
				TRL supports control flow operations using `if`, `else if`, and `else`. Here's an
				example:

				```
				$pattern = /(foo|bar)/

				if
				```
				"""
		}

		"Assignment": {
			href: "assignment"

			description: """
				You can assign values to object fields or [variables](#variables) using a single
				equals sign (`=`). Some examples:

				* `.is_success = (.code > 200) && (.code <= 299)`
				* `$pattern = /(foo|bar)/g`
				* `. = parse_json(.)`
				* `.request.id = uuidv4()`

				When assigning a value to an object field, if the field doesn't already exist it's
				created an assigned the value; if the field does already exist, the value is
				re-assigned.
				"""

			examples: [
				".request_id = uuidv4()",
				"$average = .total / .number",
				".partition_id = .status_code",
				".is_server_error = .status_code == 500",
			]
		}

		"Variables": {
			href: "variables"

			description: """
				You can assign values to variables in TRL. Variables in TRL are prefixed with a `$`
				and their names need to be [snake case](\(urls.snake_case)), as in `$myvar`,
				`$my_var`, `$this_is_my_variable`, etc.
				"""

			examples: [
				"$status_code = .code",
				#"$my_string = "Hello, Clarice""#,
				#"""
					$url_pattern = /^http\://[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$/
					$is_url = match(.url, $url_pattern)
					.has_proper_format = $is_url
					del(.url)
					"""#,
			]
		}

		"Blocks": {
			href: "blocks"

			description: """
				TRL supports organizing expressions into blocks using curly braces. Everything
				inside of a block is evaluated as a single expression. In this example, the value
				assigned to the variable `$success` is `true` if the value of the `status_code`
				field is `201`:

				```
				$success = {
					$success_codes = [200, 201, 202, 204]
					$code = .status_code
					contains($success_codes, $code)
				}
				```

				You can also create single-line blocks by separating the expressions with a
				semicolon (`;`). This block would be the equivalent of the one above:

				```
				$success =
				```
				"""

			examples: [
				"$"
			]
		}

		"Operators": {
			href: "operators"

			description: """
				TRL offers a standard set of operators that should be familiar from many other
				programming languages.

				TRL supports the standard [order of operations](\(urls.order_of_ops)). Thus,
				`(2 * 2) + 8` makes `12`, `10 / (2 + 3)` makes `2`, `true && (false || true)` makes
				`true`, and so on.
				"""

			examples: [
				"exists(.request_id) && !exists(.username)",
				".status_code == 200",
				#".user.plan != "enterprise" && .user.role == "admin""#,
			]

			operators: {
				"Boolean": {
					"&&": "And"
					"||": "Or"
					"!":  "Not"
				}
				"Equality": {
					"==": "Equals"
					"!=": "Not equals"
				}
				"Comparison": {
					">":  "Greater than"
					"<":  "Less than"
					">=": "Greater than or equal to"
					"<=": "Less than or equal to"
				}
				"Arithmetic": {
					"+": "Plus"
					"-": "Minus"
					"/": "Divide by"
					"*": "Multiply by"
					"%": "Modulo"
				}
			}
		}
	}
}
