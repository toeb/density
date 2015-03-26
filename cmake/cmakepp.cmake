## cmakepp 
##
## An enhancement suite for CMake
## 
##
## This file is the entry point for cmakepp. If you want to use the functions 
## just include this file.
##
## it can also be used as a module file with cmake's find_package() 
cmake_minimum_required(VERSION 2.8.7)
get_property(is_included GLOBAL PROPERTY cmakepp_include_guard)
if(is_included)
  _return()
endif()
set_property(GLOBAL PROPERTY cmakepp_include_guard true)
cmake_policy(SET CMP0007 NEW)
cmake_policy(SET CMP0012 NEW)
if(POLICY CMP0054)
  cmake_policy(SET CMP0054 OLD)
endif()
# installation dir of cmakepp
set(cmakepp_base_dir "${CMAKE_CURRENT_LIST_DIR}")
# include functions needed for initializing cmakepp
include(CMakeParseArguments)
# get temp dir which is needed by a couple of functions in cmakepp
# first uses env variable TMP if it does not exists TMPDIR is used
# if both do not exists current_list_dir/tmp is used
if(UNIX)
  set(cmakepp_tmp_dir $ENV{TMPDIR} /var/tmp)
else()
  set(cmakepp_tmp_dir $ENV{TMP}  ${CMAKE_CURRENT_LIST_DIR}/tmp)
endif()
list(GET cmakepp_tmp_dir 0 cmakepp_tmp_dir)
file(TO_CMAKE_PATH "${cmakepp_tmp_dir}" cmakepp_tmp_dir)
# dummy function which is overwritten and in this form just returns the temp_dir
function(cmakepp_config key)
	return("${cmakepp_tmp_dir}")
endfunction()
## create invoke later functions 
function(task_enqueue callable)
  ## semicolon encode before string_encode_semicolon exists
  string(ASCII  31 us)
  string(REPLACE ";" "${us}" callable "${callable}")
  set_property(GLOBAL APPEND PROPERTY __initial_invoke_later_list "${callable}") 
  return()
endfunction()
  
## includes all cmake files of cmakepp 



# parses an abstract syntax tree from str
function(ast str language)
  language("${language}")
  ans(language)
  # set default root definition to expr
  set(root_definition ${ARGN})
  if(NOT root_definition)
    
    map_get("${language}"  root_definition)
    ans(root_definition)
  endif()



  # transform str to a stream
  token_stream_new(${language} "${str}")
  ans(stream)
  # parse ast and return result
  ast_parse(${stream} "${root_definition}" ${language})
  return_ans()
endfunction()





  function(ast_eval ast context)
    if(ARGN)
      set(args ${ARGN})
      list_pop_front( args)
      ans(ast_language)
      map_tryget(${ast_language}  evaluators)
      ans(ast_evaluators)
      function_import_table(${ast_evaluators} ast_evaluator_table)

    endif()
    if(NOT ast_evaluators)
      message(FATAL_ERROR "no ast_evaluators given")
    endif()
  
    #message("evaluator prefix ${ast_evaluators}... ${ARGN}")
    map_get(${ast}  types)
    ans(types)
    is_map("${ast_evaluators}" )
    ans(ismap)
    while(true)
      list_pop_front( types)    
      ans(type) 
      map_tryget(${ast_evaluators}  "${type}")
      ans(eval_command)
     # message("eval command ist ${eval_command}")
      # avaible vars
      # ast context ast_language ast_evaluators
      # available commands ast_evaluator_table
      if(COMMAND "${eval_command}")
        ast_evaluator_table(${type})
        ans(res)
        return_ref(res)
      endif()
      #if(COMMAND "${eval_command}")
       # eval("${eval_command}(\"${ast}\" \"${scope}\")")
        #ans(res)
        #return_ans()
      #endif()
    endwhile()
  endfunction()





  function(ast_eval_assignment ast scope)
    message("eval assignment")
    map_get(${ast} children)
    #ans(children)

    #address_get(${children})
    ans(rvalue)
    list_pop_front( rvalue)
    ans(lvalue)
    address_print("${lvalue}")
    address_print("${rvalue}")
    ast_eval(${rvalue} ${scope})
    ans(val)
    message("assigning value ${val} to")

    map_get(${lvalue} types)
    ans(types)
    message("types for lvalue ${types}")

    map_get(${lvalue} identifier)
    ans(identifier)
    map_set(${scope} "${identifier}" ${val})

  endfunction()




function(ast_eval_identifier ast scope)
  map_get(${ast}  data)
  ans(identifier)
  message("resolving identifier: ${identifier} in '${scope}'")

  map_has(${scope}  "${identifier}")
  ans(has_value)
  if(has_value)
    map_get(${scope}  "${identifier}")
    ans()
    return_ref(value)
  endif()
  #message("no value in scope")

  if(COMMAND "${identifier}")
   # message("is command")
    return_ref(identifier)
  endif()

  if(DEFINED "${identifier}")
    message("is a cmake var")
    return_ref(${identifier})
  endif()
  return()  
  endfunction()







  function(ast_eval_literal ast scope)
    map_get(${ast} literal data)
    ans(literal)
    return_ref(literal)
  endfunction()





function(ast_parse stream definition_id )

  #message_indent_push()
  if(ARGN)
      set(args ${ARGN})
      list_pop_front( args)
      ans(ast_language)

      map_get(${ast_language}  parsers)
      ans(ast_parsers)
      map_get(${ast_language}  definitions)
      ans(ast_definitions)
      function_import_table(${ast_parsers} __ast_call_parser)

#      json_print(${ast_definitions})
  else()
      if(NOT ast_language)
          message(FATAL_ERROR "missing ast_language")
      endif()
  endif()

 # map_get(${ast_language} parsers parsers)
  map_get("${ast_definitions}"  "${definition_id}")
  ans(definition)
 
  map_tryget(${definition}  node)
  ans(create_node)
  map_get(${definition}  parser)  
  ans(parser)
  map_get(${ast_parsers}  "${parser}")
  ans(parser_command)
  map_tryget(${definition}  peek)
  ans(peek)

  #message("trying to parse ${definition_id} with ${parser} parser")
  if(peek)
    token_stream_push(${stream})
  endif()  
  #eval("${parser_command}(\"${definition}\" \"${stream}\" \"${create_node}\")")

  __ast_call_parser("${parser}" "${definition}" "${stream}" "${create_node}")
  ans(node)
  if(peek)
    token_stream_pop(${stream})
  endif()
 
 #if(node)
 #  message(FORMAT "parsed {node.types}")
 #else()
 #  message("failed to parse ${definition_id}")
 #endif()
 #  message_indent_pop()
  return_ref(node)
endfunction()




function(ast_parse_any )#definition stream create_node definition_id
  # check if definition contains "any" property
  map_tryget(${definition}  any)
  ans(any)
#  address_get(${any})
#  ans(any)
  
  # try to parse any of the definitions contained in "any" property
  set(node false)
  foreach(def ${any})    
    ast_parse(${stream} "${def}")
    ans(node)
    if(node)
      break()
    endif()
  endforeach()

  # append definition to current node if a node was returned
  is_address("${node}")
  ans(is_map)
  if(is_map)
  
    map_append(${node} types ${definition_id})
  endif()
  
  
  
  return_ref(node)
endfunction()






  function(ast_parse_empty )#definition stream create_node
    map_tryget(${definition}  empty)
    ans(is_empty)
    if(NOT is_empty)
      return(false)
    endif()
   # message("parsed empty!")
    if(NOT create_node)
      return(true)
    endif()

    map_new()
    ans(node)
    return(${node})
  endfunction()




function(ast_parse_end_of_stream)
  token_stream_isempty(${stream})
  return_ans()
endfunction()






 function(ast_parse_list )#definition stream create_node
 
   # message("parsing list")
    token_stream_push(${stream})

    map_tryget(${definition}  begin)
    ans(begin)
    map_tryget(${definition}  end)
    ans(end)
    map_tryget(${definition}  separator)
    ans(separator)
    map_get(${definition}  element)
    ans(element)
   # message(" ${begin} <${element}> <${separator}> ${end}")
    
    #message("create node ${create_node}")
    if(begin)
      ast_parse(${stream} ${begin})
      ans(begin_ast)
      
      if(NOT begin_ast)
        token_stream_pop(${stream})
        return(false)
      endif()

    endif()
    set(child_list)
    while(true)
      if(end)
        ast_parse(${stream} ${end})
        ans(end_ast)
        if(end_ast)
          break()
        endif()
      endif()

      if(separator)
        if(child_list)
          ast_parse(${stream} ${separator})
          ans(separator_ast)

          if(NOT separator_ast)
            token_stream_pop(${stream})
          #  message("failed")
            return(false)
          endif()
        endif()
      endif()
      
      ast_parse(${stream} ${element})
      ans(element_ast)

      if(NOT element_ast)
        #failed because no element was found
        if(NOT end)
          break()
        endif()
        return(false)
      endif()
      list(APPEND child_list ${element_ast})

     # message("appending child ${element_ast}")

      

    endwhile()
    #message("done ${create_node}")
    token_stream_commit(${stream})

    if(NOT create_node)
      return(true)
    endif()
#    message("creating node")

    is_map("${begin_ast}" )
    ans(isnode)
    if(NOT isnode)
      set(begin_ast)
    endif()
    is_map("${end_ast}" )
    ans(isnode)
    if(NOT isnode)
      set(end_ast)
    endif()
    map_tryget(${definition}  name)
    ans(def)
    map_new()
    ans(node)
    map_set(${node} types ${def})
    map_set(${node} children ${begin_ast} ${child_list} ${end_ast})
    return(${node})
  endfunction()





  function(ast_parse_match definition stream create_node)
    # check if definition can be parsed by ast_parse_match
    map_tryget("${definition}"  match)
    ans(match)
    if(NOT match)
      return(false)
    endif()

    # take string specified in match from stream (if stream does)
    # not start with "${match}" nothing is returned
   # message("matching match ${match}")
#    stream_print(${stream})
    stream_take_string(${stream} "${match}")
    ans(res)
    # could not parse if stream did not match "${match}"
    if("${res}_" STREQUAL "_")
      return(false)
    endif()

    # return result
    if(NOT create_node)
      return(true)
    endif()
    map_new(node)
    ans(node)
    map_set(${node} data ${data})
    return(${node})
 endfunction()





  function(ast_parse_regex definition stream create_node)
    nav(regex = "definition.regex")
    # regex - try match
    if(NOT regex)
      return(false)
    endif()
   # message("regex: ${regex}")
    stream_take_regex(${stream} "${regex}")
    ans(match)
  #  message("matched: '${match}'")
    if(NOT match)
      return(false)
    endif()
    nav(replace = definition.replace)
    if(replace)
      #message("replace: ${replace}")
      string(REGEX REPLACE "${regex}" "\\${replace}" match "${match}")
    endif()
    if(NOT create_node)
     # message("create_node: ${create_node}")
      return(true)
    endif()
    map_new()
    ans(node)
    map_set(${node} data "${match}")
    return(${node})
  endfunction()




function(ast_parse_sequence )#definition stream create_node definition_id
  map_tryget("${definition}"  sequence)
  ans(sequence)
  set(rsequence)
  if(NOT sequence)
    map_tryget("${definition}"  rsequence)
    ans(sequence)
    set(rsequence true)
  endif()
  if(NOT sequence)
    message(FATAL_ERROR "expected a sequence or a rsequence")
  endif()
  # deref ref array
#  address_get(${sequence} )
#  ans(sequence)
  
  # save current stream
  #message("push")
  token_stream_push(${stream})

  # empty var for sequence
  set(ast_sequence)

  # loop through all definitions in sequence
  # adding all resulting nodes in order to ast_sequence
  foreach(def ${sequence})
    ast_parse(${stream} "${def}")
    ans(res)
    if(res) 
      is_map(${res} )
      ans(ismap)
      if(ismap)
        list(APPEND ast_sequence ${res})
      endif()
    else()
     # message("pop")
      token_stream_pop(${stream})
      return(false)
    endif()
   
  endforeach()
  token_stream_commit(${stream})
  # return result
  if(NOT create_node)
    return(true)
  endif()
  map_new()
  ans(node)
  map_set(${node} types ${definition_id})
  
  map_set(${node} children ${ast_sequence})
  return(${node})
endfunction()






  function(ast_parse_token )#definition stream create_node definition_id
    #message(FORMAT "trying to parse {definition.name}")
   # address_print("${definition}")
   # address_print(${definition})

    token_stream_take(${stream} ${definition})
    ans(token)

    if(NOT token)
      return(false)
    endif()
    
    #message(FORMAT "parsed {definition.name}: {token.data}")
    if(NOT create_node)
      return(true)
    endif()

    map_tryget(${definition}  replace)
    ans(replace)
    if(replace)
      map_get(${token}  data)
      ans(data)
      map_get(${definition}  regex)
      ans(regex)
      string(REGEX REPLACE "${regex}" "\\${replace}" data "${data}")
      #message("data after replace ${data}")
      map_set_hidden(${token} data "${data}")
    endif()
    
    map_set_hidden(${token} types ${definition_id})
    return(${token})

  endfunction()





  function(evaluate str language expr)
    language(${language})
    ans(language)

    set(scope ${ARGN})
    is_map("${scope}" )
    ans(ismap)
    if(NOT ismap)
      map_new()
      ans(scope)
      foreach(arg ${ARGN})
        map_set(${scope} "${arg}" ${${arg}})
      endforeach()
    endif()


    map_new()
    ans(context)
    map_set(${context} scope ${scope})

  #  message("expr ${expr}")

    ast("${str}" ${language} "${expr}")
    #return("gna")
    ans(ast) 
   # address_print(${ast})
    ast_eval(${ast} ${context} ${language})
    ans(res)
    if(NOT ismap)
      map_promote(${scope})
    endif()
    return_ref(res)
  endfunction()




function(expr_compile_assignment) # scope, ast

  #message("compiling assignment")
  map_tryget(${ast}  children)
  ans(children)
  list_extract(children lvalue_ast rvalue_ast)

  map_tryget(${lvalue_ast}  types)
  ans(types)
  list_extract(types lvalue_type) 
  set(res)


  if("${lvalue_type}" STREQUAL "cmake_identifier" )
    #message("assigning cmake identifier")
    map_tryget(${lvalue_ast}  children)
    ans(children)
    list_extract(children identifier_ast)
    map_tryget(${identifier_ast}  data)
    ans(identifier)
    set(res "
  set(assignment_key \"${identifier}\")
  set(assignment_scope \"\${global}\")")
  elseif("${lvalue_type}" STREQUAL "identifier")
   # message("assigning identifier")
    map_tryget(${lvalue_ast}  data)
    ans(identifier)
    set(res "
  set(assignment_key \"${identifier}\")
  set(assignment_scope \"\${this}\")")
  elseif("${lvalue_type}" STREQUAL "indexation")
    map_tryget(${lvalue_ast}  children)
    ans(indexation_ast)
    ast_eval(${indexation_ast} ${context})
    ans(indexation)
    set(res "
  ${indexation}
  ans(assignment_key)
  set(assignment_scope \"\${this}\")")
  endif()

  ast_eval(${rvalue_ast} ${context})
  ans(rvalue)
  set(res "
  # expr_compile_assignment
  ${rvalue}
  ans(rvalue)
  ${res}
  map_set(\"\${assignment_scope}\" \"\${assignment_key}\" \"\${rvalue}\" )
  set_ans_ref(rvalue)
  # end of expr_compile_assignment")
  return_ref(res)   
endfunction()




function(expr_compile_bind)
  set(res "
  # expr_compile_bind 
  set(this \"\${left}\")
  # end of expr_compile_bind")
  return_ref(res)
endfunction()




function(expr_compile_call)
  map_tryget(${ast}  children) 
  ans(argument_asts)
  set(arguments)
  set(evaluation)
  set(i 0)


  make_symbol()
  ans(symbol)

  foreach(argument_ast ${argument_asts})
    ast_eval(${argument_ast} ${context})
    ans(argument)

    set(evaluation "${evaluation}
  ${argument}
  ans(${symbol}_arg${i})")
    set(arguments "${arguments}\"\${${symbol}_arg${i}}\" " )
    math(EXPR i "${i} + 1")
  endforeach()

  set(res "
  # expr_compile_call 
  ${evaluation}
  call(\"\${left}\"(${arguments}))
  # end of expr_compile_call")

  return_ref(res)
endfunction()




function(expr_compile_cmake_identifier)
  #message("cmake_identifier")
  #address_print(${ast})
  map_get(${ast}  children)
  ans(identifier)
  map_get(${identifier}  data)
  ans(identifier)
  
  set(res "
  #expr_compile_cmake_identifier
  if(COMMAND \"${identifier}\")
    set_ans(\"${identifier}\")
  else() 
    set_ans_ref(\"${identifier}\") 
  endif()
  # end of expr_compile_cmake_identifier")
  return_ref(res)
endfunction()




function(expr_compile_coalescing)
  map_tryget(${ast}  children)
  ans(expr_ast)
  ast_eval(${expr_ast} ${context})
  ans(expr)
  set(res "
  # expr_compile_coalescing 
  if(NOT left)
    ${expr}
  endif()
  # end of expr_compile_coalescing")
  return_ref(res)
endfunction()




function(expr_compile_expression)
  #message("compiling expression")
  map_get(${ast}  children)
  ans(children)
  set(result "")
  
  list(LENGTH children len)
  if(len GREATER 1)

    make_symbol()
    ans(symbol)
    foreach(rvalue_ast ${children})
      ast_eval(${rvalue_ast} ${context})
      ans(rvalue)

      set(result "${result}
  ${rvalue}
  ans(left)")
      map_set(${context} left ${rvalue})
      map_set(${context} left_ast ${rvalue_ast})
    endforeach()
    
    map_append_string(${context} code "
#expr_compile_expression
function(${symbol})
  set(left)
  ${result}
  return_ref(left)
endfunction()
#end of expr_compile_expression")

    set(symbol "
  #expr_compile_expression
  ${symbol}()
  #end of expr_compile_expression")
  else()
    ast_eval(${children} ${context})
    ans(symbol)
  endif()


  return_ref(symbol)
endfunction()




function(expr_compile_expression_statement) # context, ast
  map_tryget(${ast}  children)
  ans(statement_ast)
  ast_eval(${statement_ast} ${context})
  ans(statement)
  set(res "
  # expr_compile_statement
  ${statement}
  # end of expr_compile_statement")
  return_ref(res)  
endfunction()




function(expr_compile_function) # context, ast
 # message("expr_compile_function")

  map_tryget(${ast} children)
  ans(children)

  #message("children ${children}")

  list_extract(children signature_ast body_ast)

  map_tryget(${signature_ast} children)
  ans(signature_identifiers)
  set(signature_vars)
  set(identifiers)
  foreach(identifier ${signature_identifiers})
    map_tryget(${identifier} data)
    ans(identifier)
    list(APPEND identifiers "${identifier}")
    set(signature_vars "${signature_vars} ${identifier}")
  endforeach()  
  #message("signature_identifiers ${identifiers}")

  map_tryget(${body_ast} types)
  ans(body_types)

  list_contains(body_types closure)
  ans(is_closure)
  
  if(is_closure)
   map_tryget(${body_ast} children)
    ans(body_ast)

  endif()

  make_symbol()
  ans(symbol)
 # message("body_types ${body_types}")

  ast_eval(${body_ast} ${context})
  ans(body)

map_append_string(${context} code "#expr_compile_function
function(\"${symbol}\"${signature_vars})
  map_new()
  ans(local)  
  map_capture(\"\${local}\" this global${signature_vars})
  ${body}
  return_ans()
endfunction()
#end of expr_compile_function")
  

  set(res "set_ans(\"${symbol}\")")

  return_ref(res)  
endfunction()




function(expr_compile_identifier)# ast context
  
#message("ast: ${ast}")
  
  map_tryget(${ast}  data)
  ans(data)
  set(res "
  # expr_compile_identifier
  #map_tryget(\"\${local}\" \"${data}\")
  scope_resolve(\"${data}\")
  obj_get(\"\${this}\" \"${data}\")
  # end of expr_compile_identifier")
  return_ref(res)
endfunction()




function(expr_compile_indexation)
  map_tryget(${ast}  children)
  ans(indexation_expression_ast)
  ast_eval(${indexation_expression_ast} ${context})
  ans(indexation_expression)

  set(res "
  # expr_compile_indexation
  ${indexation_expression}
  ans(index)
  set(this \"\${left}\")
  map_get(\"\${this}\" \"\${index}\")
  # end of expr_compile_indexation")


  return_ref(res)
endfunction()




function(expr_compile_list)
  map_tryget(${ast}  children) 
  ans(element_asts)
  set(arguments)
  set(evaluation)
  set(i 0)

  make_symbol()
  ans(symbol)
  set(elements)
  foreach(element_ast ${element_asts})
    ast_eval(${element_ast} ${context})
    ans(element)

    set(evaluation "${evaluation}
  ${element}
  ans(${symbol}_arg${i})")
    set(elements "${elements}\"\${${symbol}_arg${i}}\" " )
    math(EXPR i "${i} + 1")
  endforeach()
  set(res "
  #expr_compile_list
  ${evaluation}
  set(${symbol} ${elements})
  set_ans_ref(${symbol})
  #end of expr_compile_list")
  return_ref(res)
endfunction()




function(expr_compile_new)
#json_print(${ast})
  map_tryget(${ast} children)
  ans(children)

  list_extract(children className_ast call_ast)

  map_tryget(${className_ast} data)
  ans(className)

  map_tryget(${call_ast} children)
  ans(argument_asts)


 # message("class name is ${className} ")

  set(arguments)
  set(evaluation)
  set(i 0)

  make_symbol()
  ans(symbol)

  foreach(argument_ast ${argument_asts})
    ast_eval(${argument_ast} ${context})
    ans(argument)

    set(evaluation "${evaluation}
  ${argument}
  ans(${symbol}_arg${i})")
    set(arguments "${arguments}\"\${${symbol}_arg${i}}\" " )
    math(EXPR i "${i} + 1")
  endforeach()

  set(res "
#expr_compile_new
${evaluation}
obj_new(\"${className}\" ${arguments})
#end of expr_compile_new
  ")


return_ref(res)
endfunction()




function(expr_compile_new_object)
  map_tryget(${ast}  children)
  ans(keyvalues)
  map_tryget(${keyvalues}  children)
  ans(keyvalues)

  make_symbol()
  ans(symbol)

  set(evaluation)
  foreach(keyvalue ${keyvalues})
    map_tryget(${keyvalue}  children)
    ans(pair)
    list_extract(pair key_ast value_ast)
    map_tryget(${key_ast}  data)
    ans(key)
    ast_eval(${value_ast} ${context})
    ans(value)
    #string(REPLACE "\${" "\${" value "${value}")
    set(evaluation "${evaluation}
    ${value}
    ans(${symbol}_tmp)
    map_set(\"\${${symbol}}\" \"${key}\" \"\${${symbol}_tmp}\")")
  endforeach()

  set(res "
  #expr_compile_new_object
  map_new()
  ans(${symbol})
  ${evaluation}
  set_ans_ref(${symbol})
  #end of expr_compile_new_object
  ")

  return_ref(res)

endfunction()




function(expr_compile_number) # scope, ast

  map_tryget(${ast}  data)
  ans(data)
  make_symbol()
  ans(symbol)
  
 
  set(res "
  # expr_compile_number
  set_ans(\"${data}\")
  # end of expr_compile_number")
  return_ref(res)  
endfunction()




function(expr_compile_parentheses)

  map_tryget(${ast}  children)
  ans(expression_ast)
  ast_eval(${expression_ast} ${context})
  ans(expression)

  set(res "
  # expr_compile_parentheses
  ${expression}
  # end of expr_compile_parentheses")


  return_ref(res)
endfunction()




function(expr_compile_statements) # scope, ast
  map_tryget(${ast}  children)
  ans(statement_asts)
  set(statements)
  #message("children: ${statement_asts}")
  list(LENGTH statement_asts len)
  set(index 0)
  foreach(statement_ast ${statement_asts})
    math(EXPR index "${index} + 1")
    ast_eval(${statement_ast} ${context})
    ans(statement)
    set(statements "${statements}
  #statement ${index} / ${len}
  ${statement}")
  endforeach()
  map_tryget(${ast}  data)
  ans(data)
  make_symbol()
  ans(symbol)
  
  make_symbol()
  ans(symbol)

  map_append_string(${context} code "
# expr_compile_statements
function(\"${symbol}\")
  ${statements}
  return_ans()
endfunction()
# end of expr_compile_statements")
  
  set(res "${symbol}()")

#  message("${res}")
  return_ref(res)  
endfunction()




function(expr_compile_string) # scope, ast

  map_tryget(${ast}  data)
  ans(data)
  make_symbol()
  ans(symbol)
  
 
  set(res "
  # expr_compile_string
  set_ans(\"${data}\")
  # end of expr_compile_string")
  return_ref(res)  
endfunction()




## file containing data from resources/expr.json 
function(expr_definition)
map()
 key("name")
  val("oocmake")
 key("phases")
 map()
  key("name")
   val("tokenize")
  key("function")
   val("token_stream_new\(/0\ /1\)")
  key("input")
   val("global")
   val("str")
  key("output")
   val("tokens")
 end()
 map()
  key("name")
   val("parse")
  key("function")
   val("ast_parse\(/0\ /1\ /2\ /3\ /4\)")
  key("input")
   val("tokens")
   val("root_definition")
   val("global")
   val("parsers")
   val("definitions")
  key("output")
   val("ast")
 end()
 map()
  key("name")
   val("compile")
  key("function")
   val("ast_eval\(/0\ /1\ /2\ /3\)")
  key("input")
   val("ast")
   val("context")
   val("global")
   val("evaluators")
  key("output")
   val("symbol")
 end()
 key("parsers")
 map()
  key("token")
   val("ast_parse_token")
  key("any")
   val("ast_parse_any")
  key("sequence")
   val("ast_parse_sequence")
  key("list")
   val("ast_parse_list")
  key("empty")
   val("ast_parse_empty")
  key("end_of_stream")
   val("ast_parse_end_of_stream")
 end()
 key("evaluators")
 map()
  key("string")
   val("expr_compile_string")
  key("number")
   val("expr_compile_number")
  key("cmake_identifier")
   val("expr_compile_cmake_identifier")
  key("call")
   val("expr_compile_call")
  key("expression")
   val("expr_compile_expression")
  key("bind")
   val("expr_compile_bind")
  key("indexation")
   val("expr_compile_indexation")
  key("identifier")
   val("expr_compile_identifier")
  key("list")
   val("expr_compile_list")
  key("new_object")
   val("expr_compile_new_object")
  key("assignment")
   val("expr_compile_assignment")
  key("parentheses")
   val("expr_compile_parentheses")
  key("null_coalescing")
   val("expr_compile_coalescing")
  key("statements")
   val("expr_compile_statements")
  key("expression_statement")
   val("expr_compile_expression_statement")
  key("function")
   val("expr_compile_function")
  key("if")
   val("expr_compile_if")
  key("while")
   val("expr_compile_while")
  key("for")
   val("expr_compile_for")
  key("foreach")
   val("expr_compile_foreach")
  key("new")
   val("expr_compile_new")
 end()
 key("root_definition")
  val("statements")
 key("definitions")
 map()
  key("statements")
  map()
   key("node")
    val("true")
   key("parser")
    val("list")
   key("element")
    val("statement")
  end()
  key("if")
  map()
   key("node")
    val("true")
   key("parser")
    val("any")
   key("any")
    val("if_else")
    val("if_only")
  end()
  key("for_keyword")
  map()
   key("parser")
    val("token")
   key("regex")
    val("for")
  end()
  key("while_keyword")
  map()
   key("parser")
    val("token")
   key("regex")
    val("while")
  end()
  key("new")
  map()
   key("parser")
    val("sequence")
   key("node")
    val("true")
   key("sequence")
    val("new_keyword")
    val("identifier")
    val("call")
  end()
  key("for")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("for_keyword")
    val("paren_open")
    val("expression")
    val("expression")
    val("expression")
    val("paren_close")
    val("statement")
  end()
  key("while")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("while_keyword")
    val("paren_open")
    val("expression")
    val("paren_close")
    val("statement")
  end()
  key("foreach")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("while_keyword")
    val("paren_open")
    val("expression")
    val("paren_close")
    val("statement")
  end()
  key("if_only")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("if_keyword")
    val("paren_open")
    val("expression")
    val("paren_close")
    val("statement")
  end()
  key("if_else")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("if_only")
    val("else_keyword")
    val("statement")
  end()
  key("if_keyword")
  map()
   key("parser")
    val("token")
   key("regex")
    val("if")
  end()
  key("else_keyword")
  map()
   key("parser")
    val("token")
   key("regex")
    val("else")
  end()
  key("expression_statement")
  map()
   key("parser")
    val("sequence")
   key("node")
    val("true")
   key("sequence")
    val("expression")
    val("end_of_statement")
  end()
  key("statement")
  map()
   key("parser")
    val("any")
   key("any")
    val("expression_statement")
  end()
  key("end_of_statement")
  map()
   key("parser")
    val("any")
   key("any")
    val("semicolon")
    val("end_of_stream")
  end()
  key("expression")
  map()
   key("node")
    val("true")
   key("parser")
    val("list")
   key("begin")
    val("value")
   key("element")
    val("operation")
   key("end")
    val("end_of_expression")
  end()
  key("function")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("function_signature")
    val("hyphen")
    val("angular_bracket_close")
    val("function_body")
  end()
  key("hyphen")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[-]")
  end()
  key("angular_bracket_open")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[<]")
  end()
  key("angular_bracket_close")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[>]")
  end()
  key("function_signature")
  map()
   key("node")
    val("true")
   key("parser")
    val("list")
   key("element")
    val("identifier")
   key("begin")
    val("paren_open")
   key("end")
    val("paren_close")
   key("separator")
    val("comma")
  end()
  key("function_body")
  map()
   key("parser")
    val("any")
   key("any")
    val("closure")
    val("expression")
  end()
  key("closure")
  map()
   key("parser")
    val("sequence")
   key("node")
    val("true")
   key("sequence")
    val("brace_open")
    val("statements")
    val("brace_close")
  end()
  key("value")
  map()
   key("parser")
    val("any")
   key("any")
    val("assignment")
    val("function")
    val("parentheses")
    val("literal")
    val("lvalue")
    val("list")
    val("new_object")
    val("new")
  end()
  key("lvalue")
  map()
   key("parser")
    val("any")
   key("any")
    val("cmake_identifier")
    val("identifier")
    val("indexation")
  end()
  key("operation")
  map()
   key("parser")
    val("any")
   key("any")
    val("assignment")
    val("identifier")
    val("call")
    val("bind")
    val("indexation")
    val("null_coalescing")
  end()
  key("null_coalescing")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("query")
    val("query")
    val("expression")
  end()
  key("query")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[?]")
  end()
  key("parentheses")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("paren_open")
    val("expression")
    val("paren_close")
  end()
  key("assignment")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("lvalue")
    val("equals")
    val("expression")
  end()
  key("indexation")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("bracket_open")
    val("expression")
    val("bracket_close")
  end()
  key("bind")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("period")
  end()
  key("new_object")
  map()
   key("node")
    val("true")
   key("parser")
    val("sequence")
   key("sequence")
    val("key_value_list")
  end()
  key("key_value_list")
  map()
   key("parser")
    val("list")
   key("node")
    val("true")
   key("begin")
    val("brace_open")
   key("end")
    val("brace_close")
   key("element")
    val("key_value")
   key("separator")
    val("comma")
  end()
  key("call")
  map()
   key("parser")
    val("list")
   key("begin")
    val("paren_open")
   key("element")
    val("expression")
   key("separator")
    val("comma")
   key("end")
    val("paren_close")
   key("node")
    val("true")
  end()
  key("end_of_expression")
  map()
   key("parser")
    val("any")
   key("peek")
    val("true")
   key("any")
    val("comma")
    val("paren_close")
    val("semicolon")
    val("bracket_close")
    val("brace_close")
    val("end_of_stream")
  end()
  key("list")
  map()
   key("parser")
    val("list")
   key("begin")
    val("bracket_open")
   key("end")
    val("bracket_close")
   key("separator")
    val("comma")
   key("element")
    val("expression")
   key("node")
    val("true")
  end()
  key("new_keyword")
  map()
   key("parser")
    val("token")
   key("regex")
    val("new")
  end()
  key("key_value")
  map()
   key("parser")
    val("sequence")
   key("node")
    val("true")
   key("sequence")
    val("key")
    val("colon")
    val("key_value_value")
  end()
  key("key_value_value")
  map()
   key("parser")
    val("any")
   key("any")
    val("list")
    val("expression")
  end()
  key("key")
  map()
   key("parser")
    val("any")
   key("any")
    val("identifier")
    val("string")
  end()
  key("identifier")
  map()
   key("parser")
    val("token")
   key("node")
    val("true")
   key("regex")
    val("\([a-zA-Z_-][a-zA-Z0-9_\\-]*\)")
   key("except")
    val("\(new|for|while\)")
  end()
  key("cmake_identifier")
  map()
   key("parser")
    val("sequence")
   key("node")
    val("true")
   key("sequence")
    val("dollar")
    val("identifier")
  end()
  key("end_of_stream")
  map()
   key("parser")
    val("end_of_stream")
  end()
  key("nothing")
  map()
   key("parser")
    val("empty")
   key("empty")
    val("true")
  end()
  key("colon")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[:]")
  end()
  key("semicolon")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[\\\\\;]")
  end()
  key("period")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[\\.]")
  end()
  key("dollar")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[\\\$]")
  end()
  key("equals")
  map()
   key("parser")
    val("token")
   key("regex")
    val("=")
  end()
  key("literal")
  map()
   key("parser")
    val("any")
   key("any")
    val("string")
    val("number")
  end()
  key("paren_close")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[\)]")
  end()
  key("paren_open")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[\(]")
  end()
  key("bracket_close")
  map()
   key("parser")
    val("token")
   key("regex")
    val("]")
  end()
  key("bracket_open")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[\\[]")
  end()
  key("brace_close")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[}]")
  end()
  key("brace_open")
  map()
   key("parser")
    val("token")
   key("regex")
    val("[{]")
  end()
  key("comma")
  map()
   key("parser")
    val("token")
   key("match")
    val(",")
  end()
  key("string")
  map()
   key("parser")
    val("token")
   key("node")
    val("true")
   key("regex")
    val("'\(\([\^']|\\\\'\)*\)'")
   key("replace")
    val("1")
  end()
  key("number")
  map()
   key("parser")
    val("token")
   key("node")
    val("true")
   key("regex")
    val("\([1-9][0-9]*\)")
  end()
  key("white_space")
  map()
   key("parser")
    val("token")
   key("ignore_token")
    val("true")
   key("regex")
    val("[\r\n\t\ ]+")
  end()
 end()
end()
ans(res)
return_ref(res)

endfunction()




function(expr_eval_call)
  map_tryget(${ast}  children) 
  ans(argument_asts)
  set(arguments)
  foreach(argument_ast ${argument_asts})
    ast_eval(${argument_ast} ${context})
    ans(argument)
    set(arguments "${arguments}\"${argument}\" " )
  endforeach()
  map_get(${context}  left)
  ans(invokation_target)
  set(invokation "${invokation_target}"("${arguments}"))
  call("${invokation}")
  return_ans()
endfunction()




function(expr_eval_cmake_identifier)
  #message("cmake_identifier")
  #address_print(${ast})
  map_get(${ast}  children)
  ans(identifier)
  map_get(${identifier}  data)
  ans(identifier)

  if(NOT "${identifier}" AND COMMAND "${identifier}")
    
  else()
    set(identifier "${${identifier}}")
  endif()
#  message("returning ${identifier}")
  return_ref(identifier)
endfunction()




function(expr_eval_identifier)# ast scope
  message("identifier")
  address_print(${ast})
endfunction()




function(expr_eval_expression)
#  message("evaluating expression")
  map_get(${ast}  children)
  ans(children)
    map_new()
    ans(new_context)
  map_set(${new_context} parent_context ${context})
  map_tryget(${context}  scope)
  ans(scope)
  map_set(${new_context} scope ${scope})

  foreach(rvalue_ast ${children})
    ast_eval(${rvalue_ast} ${new_context})
    ans(rvalue)
    map_set(${new_context} left ${rvalue})
    map_set(${new_context} left_ast ${rvalue_ast})
  endforeach()


  map_tryget(${new_context}  left)
  ans(left)
  return_ref(left)
endfunction()




function(expr_eval_string) # scope, ast
  map_tryget(${ast}  data)
  ans(data)
  return_ref(data)  
endfunction()




function(expr_compile str)
  map_new()
  ans(expression_cache)
  address_set(__expression_cache ${expression_cache})
  function(expr_compile str)
    set(ast)
    address_get(__expression_cache )
    ans(expression_cache)
    map_tryget(${expression_cache}  "${str}")
    ans(symbol)
    if(NOT symbol)
      # get ast
      language("oocmake")
      ans(language)
      if(NOT language)
        cmakepp_config(base_dir)
        ans(base_dir)
        language("${base_dir}/resources/expr.json")
        ans(language)
      endif()
      #message("compiling ast for \"${str}\"")
      ast("${str}" oocmake "")
      ans(ast)
      #message("ast created")
      # compile to cmake
      map_new()
      ans(context)
      map_new()
      ans(scope)
      map_set(${context} scope ${scope})    
      ast_eval(${ast} ${context} ${language})
      ans(symbol)
      map_tryget(${context}  code)
      ans(code)
      if(code)
       # message("${code}")
        set_ans("")
        eval("${code}")
      endif()
      map_set(${expression_cache} "${str}" ${symbol})
    endif()
    #eval("${symbol}")
    #return_ans()
    return_ref(symbol)
  endfunction()
  expr_compile("${str}")
  return_ans()
endfunction()




function(expr_import str function_name)
  expr_compile("${str}")
  ans(symbol)
  set_ans("")
  eval("
function(${function_name})
  is_map(\"${global}\" )
  ans(ismap)
  if(NOT ismap)
    map_new()
    ans(global)
  endif()
  ${symbol}
  ans(res)
  if(NOT ismap)
    map_promote(${global})
  endif()
  return_ref(res)
endfunction()")
  return_ans()
endfunction()





  function(ast_json_eval_array )#ast scope
    map_get(${ast}  children)
    ans(values)
    set(res)
    foreach(value ${values})
      ast_eval(${value} ${context})
      ans(evaluated_value)
      list(APPEND res "${evaluated_value}")
    endforeach()
    return_ref(res)
  endfunction()





  function(ast_json_eval_boolean )#ast scope
    map_get(${ast}  data)
    ans(data)
    return_ref(data)
  endfunction()





  function(ast_json_eval_key_value )#ast scope
    map_get(${ast}  children)
    ans(value)
    list_pop_front( value)
    ans(key)
    ast_eval(${key} ${context})
    ans(key)
    ast_eval(${value} ${context})
    ans(value)

    #message("keyvalue ${key}:${value}")
    map_set(${context} ${key} ${value})
  endfunction()





  function(ast_json_eval_null )#ast scope
    map_get(${ast}  data)
    ans(data)
    return()
  endfunction()





  function(ast_json_eval_number )#ast scope
    map_get(${ast}  data)
    ans(data)
    return_ref(data)
  endfunction()





  function(ast_json_eval_object )#ast scope
    map_new()
    ans(map)
    map_get(${ast}  children)
    ans(keyvalues)
    foreach(keyvalue ${keyvalues})
      ast_eval(${keyvalue} ${map})
    endforeach()
    return(${map})
  endfunction()





  function(ast_json_eval_string )#ast scope
    map_get(${ast}  data)
    ans(data)
    return_ref(data)
  endfunction()





  function(lang target context)    
    #message("target ${target}")
    obj_get(${context} phases)
    ans(phases)

   

    # get target value from
    obj_has(${context} "${target}")
    ans(has_target)
    if(NOT has_target)
      message(FATAL_ERROR "missing target '${target}'")        
    endif()
    obj_get(${context} "${target}")
    ans(current_target)

    if("${current_target}_" STREQUAL "_")
        return()
    endif()

    # check if phase
    list_contains(phases "${current_target}")
    ans(isphase)    
    # if not a phase just return value
    if(NOT isphase)
      return_ref("current_target")
    endif()


    # target is phase 
    map_tryget("${current_target}" name)
    ans(name)


    # get inputs for current target
    obj_get("${current_target}" "input")
    ans(required_inputs)

    # setup required imports
    map_new()
    ans(inputs)
    foreach(input ${required_inputs})
        #message_indent_push()
        #message("getting ${input} ${required_inputs}")

        lang("${input}" ${context})
        ans(res)
        #message("got ${res} for ${input}")
        #message_indent_pop()
        map_set(${inputs} "${input}" "${res}")
    endforeach()

    # handle function call
    map_tryget("${current_target}" function)
    ans(func)
    if("${func}" MATCHES "(.*)\\(([^\\)]*)\\)$" )
        set(func "${CMAKE_MATCH_1}")
        set(arg_assignments "${CMAKE_MATCH_2}")
        string(REPLACE " " ";" arg_assignments "${arg_assignments}")
    else()
        message(FATAL_ERROR "failed to parse targets function")
    endif()

    # curry function to specified arguments
    curry3(() => "${func}"(${arg_assignments}))
    ans(func)

    # compile argument string

    map_keys(${inputs})
    ans(keys)
    set(arguments_string)
    foreach(key ${keys})
      map_tryget(${inputs} "${key}")
      ans(val)
      cmake_string_escape("${val}")
      ans(val)
      #message("key ${key} val ${val}")
      #string(REPLACE "\\" "\\\\"  val "${val}")
      #string(REPLACE "\"" "\\\"" val "${val}")
      set(arguments_string "${arguments_string} \"${val}\"")
    endforeach()
    # call curried function - note that context is available to be modified
    set(func_call "${func}(${arguments_string})")
 
    #message("lang: target '${target}'  func call ${func_call}")
   set_ans("")
    eval("${func_call}")
    ans(res)    
   # message("res '${res}'")
    obj_set(${context} "${target}" "${res}")

    # set single output to return value
    map_tryget(${current_target} output)
    ans(outputs)
    list(LENGTH outputs len)
    if(${len} EQUAL 1)
      set(${context} "${outputs}" "${res}")
    endif()

    map_tryget(${context} "${target}")
    ans(res)

    return_ref(res)
  endfunction()




# executes the language file, input can be given by a key value list
  function(lang2 target language)
    map_from_keyvaluelist("" ${ARGN})
    ans(ctx)
    language("${language}")
    ans(language)
    
    obj_setprototype("${ctx}" "${language}")
    lang("${target}" "${ctx}")
    ans(res)

    
    return_ref(res)
  endfunction()




function(language name)
  map_new()
  ans(language_map)
  address_set(language_map "${language_map}")


function(language name)
  ## get cached language
  address_get(language_map)
  ans(language_map)

  is_map("${name}")
  ans(ismp)
  if(ismp)
    map_tryget(${name}  initialized)
    ans(initialized)
    if(NOT initialized)
      language_initialize(${name})
    endif()
    map_tryget(${name} name)
    ans(lang_name)
    map_tryget(${language_map} ${lang_name})
    ans(existing_lang)
    if(NOT existing_lang)
      map_set(${language_map} ${lang_name} ${name})
    endif()
    return_ref(name)
  endif()

  map_tryget(${language_map}  "${name}")
  ans(language)


  if(NOT language)
    language_load(${name})
    ans(language)

    if(NOT language)
      return()
    endif()
    map_set(${language_map} "${name}" ${language})
    
    map_get(${language}  name)
    ans(name)
    map_set(${language_map} "${name}" ${language})
    set_ans("")
    eval("function(eval_${name} str)
    language(\"${name}\")
    ans(lang)
    ast(\"\${str}\" \"${name}\" \"\")
    ans(ast)
    map_new()
    ans(context)
      #message(\"evaling '\${ast}' with lang '\${lang}' context is \${context} \")
    ast_eval(\${ast} \${context} \${lang})
    ans(res)
    return_ref(res)
    endfunction()")
  endif()
  return_ref(language)
endfunction()

language("${name}" ${ARGN})
return_ans()

endfunction()





function(language_initialize language)
  # sets up the language object
    
  map_tryget(${language}  initialized)
  ans(initialized)
  if(initialized)
    return(${language})
  endif()


  # setup token definitions

  # setup definition names
  map_get(${language}  definitions)
  ans(definitions)
  map_keys(${definitions})
  ans(keys)
  foreach(key ${keys})
    map_get(${definitions}  ${key})
    ans(definition)
    map_set(${definition} name ${key} )
  endforeach()  

  #
  token_definitions(${language})
  ans(token_definitions)
  map_set(${language} token_definitions ${token_definitions})

  map_set(${language} initialized true)


  # extract phases
  map_tryget(${language} phases)
  ans(phases)
#  is_address("${phases}")
#  ans(isref)
#  if(isref)
#    address_get(${phases})
#    ans(phases)
#  endif()
  map_set(${language} phases "${phases}")


  # setup self reference
  map_set(${language} global ${language})
  

  # setup outputs
  foreach(phase ${phases})
    map_tryget(${phase} name)
    ans(name)
    map_set("${language}" "${name}" "${phase}")

    map_tryget("${phase}" output)
    ans(outputs)
    if(outputs)
 #     is_address("${outputs}")
 #     ans(isref)
#      if(isref)
 #       address_get(${outputs})
  #      ans(outputs)
   #   endif()
      map_set("${phase}" output "${outputs}")

      foreach(output ${outputs})
        map_set(${language} "${output}" "${phase}")
      endforeach()
    endif()
  endforeach()



  # setup inputs
  foreach(phase ${phases})
    map_tryget("${phase}" input)
    ans(inputs)
    if(inputs)
#      is_address("${inputs}")
 #     ans(isref)
  #    if(isref)
   #     address_get(${inputs})
    #    ans(inputs)
    # endif()
      map_set("${phase}" input "${inputs}")
     # message("inputs for phase ${phase} ${inputs}")

      foreach(input ${inputs})
        map_tryget(${language} "${input}")
        ans(val)
        if(NOT val)
          map_set(${language} "${input}" "missing")
        
         # message("missing input: ${input}")
        endif()

      endforeach()
    endif()
  endforeach()


endfunction()




function(language_load definition_file)
  if(NOT EXISTS "${definition_file}")
    return()
  endif()
  json_read("${definition_file}")
  ans(language)
  string(MD5 hash "${data}")
  map_set(${language} md5 "${hash}")
 # address_print(${language})
  if(NOT language)
    return()
  endif()
  language_initialize(${language})

  return_ref(language)
endfunction()






function(make_symbol)
  address_get(symbol_count)
  ans(i)
  if(NOT i)
    function(make_symbol)
      address_get(symbol_count )
      ans(i)
      math(EXPR i "${i} + 1")
      address_set(symbol_count "${i}")
      return("symbol_${i}_${symbol_cache_key}")
    endfunction()
    address_set(symbol_count 1)
    return(symbol_1)
  endif()
  message(FATAL_ERROR "make_symbol")
 endfunction()




function(script str)


  map_new()
  ans(expression_cache)
  map_set(global expression_cache ${expression_cache})
  function(script str)
    language("oocmake")
    ans(lang)
    if(NOT lang)
      #cmakepp_config(base_dir)
      #ans(base_dir)

      #language("${base_dir}/resources/expr.json")
      expr_definition()
      ans(lang)
      language("${lang}")
      ans(lang)

    endif()
    map_tryget("${lang}" md5)
    ans(language_hash)
    string(MD5 script_language_hash "${str}${language_hash}")  
    cmakepp_config(temp_dir)
    ans(temp_dir)
    set(obj_file "${temp_dir}/expressions/expr_${script_language_hash}.cmake")
    map_tryget(global expression_cache)
    ans(expression_cache)

    map_tryget(${expression_cache} "${script_language_hash}")
    ans(symbol)
    if(symbol)

    elseif(EXISTS "${obj_file}")
      include("${obj_file}")
      ans(symbol)
      map_set(${expression_cache} "${script_language_hash}" "${symbol}")
    else()
#      echo_append("compiling expression to ${obj_file} ...")
      map_new()
      ans(context)

      map_new(scope)
      ans(scope)

      map_set(${context} scope "${scope}")
      map_set(${context} cache_key "${script_language_hash}")
      set(symbol_cache_key "${script_language_hash}")
      ast("${str}" oocmake "")
      ans(ast)

      ast_eval(${ast} ${context} ${lang})
      ans(symbol)
      string(REPLACE "\"" "\\\"" escaped "${symbol}")
      string(REPLACE "$" "\\$" escaped "${escaped}")
      map_tryget(${context} code)
      ans(code)
 #     message("done")
      file(WRITE "${obj_file}" "${code}\nset(__ans \"${escaped}\")")
      if(code)
        set_ans("")
        eval("${code}")
      endif()

    endif()

  is_map("${global}" )
    ans(ismap)
    if(NOT ismap)
      map_new()
      ans(global)
    endif()
    set_ans("")
    eval("${symbol}")
    ans(res)

    if(NOT ismap)

      map_promote(${global})
    endif()
    return_ref(res)
  endfunction()
  script("${str}")
  return_ans()
endfunction()




# parses str into a linked list of tokens 
# using token_definitions
function(tokens_parse token_definitions str)
  map_new()
  ans(first_token)
  set(last_token ${first_token})
  while(true) 
    # recursion anker
    string_isempty( "${str}")
    ans(isempty)
    if(isempty)
      map_tryget(${first_token}  next)
      ans(first_token)
      return(${first_token})
    endif()

    set(token)
    set(ok)
    foreach(token_definition ${token_definitions})
      map_tryget(${token_definition}  regex)
      ans(regex)
    #  message("trying ${regex} with '${str}'")
      #set(match)
      string(REGEX MATCH "^(${regex})" match "${str}")
      list(LENGTH match len)
      if("${len}" GREATER 0)
        map_tryget(${token_definition} except)
        ans(except)
        list(LENGTH except hasExcept)
        if(NOT hasExcept OR NOT "_${match}" MATCHES "_(${except})")

          #message(FORMAT "matched {token_definition.name}  match: '${match}' ")
          #message("stream ${str}")     
          string(LENGTH "${match}" len)
          string(SUBSTRING "${str}" "${len}" -1 str)
          token_new(${token_definition} "${match}")
          ans(token)
     #     message(FORMAT "token {token_definition.regex} matches ${match}")
          set(ok true)
          break()
        endif()
      endif()
    endforeach()

    if(NOT ok)
#      message("failed - not a token  @ ...${str}")
      return()
    endif()

    if(token)
      if(last_token)
        map_set(${last_token} next ${token})
      endif()
      set(last_token ${token})
    endif()
  endwhile()

endfunction()




# returns the token definitions of a language 
function(token_definitions language)
  map_get(${language}  definitions)
  ans(definitions)
  map_keys(${definitions} )
  ans(keys)
  set(token_definitions)
  foreach(key ${keys})
    map_get(${definitions}  ${key})
    ans(definition)
    map_tryget(${definition}  parser)
    ans(parser)
    if("${parser}" STREQUAL "token")
      map_set(${definition} name "${key}")
      map_tryget(${definition}  regex)
      ans(regex)
      if(regex)
        map_set(${token_definition} regex "${regex}")
      else()
        map_tryget(${definition}  match)
        ans(match)
        string_regex_escape("${match}")
        ans(match)
        map_set(${definition} regex "${match}")
      endif()
      list(APPEND token_definitions ${definition})
    endif()
  endforeach()
  return_ref(token_definitions)
endfunction()




  function(token_new definition data)
    map_tryget(${definition}  ignore_token)
    ans(ignore_token)
    if(ignore_token)
      return()
    endif()
    map_new()
    ans(token)
    map_set(${token} definition ${definition})
    map_set(${token} data "${data}")
    return_ref(token)
  endfunction()





  function(token_stream_commit stream)
    map_get(${stream}  stack)
    ans(stack)
    stack_pop(${stack})
  endfunction()





  function(token_stream_isempty stream)
    map_tryget(${stream}  current)
    ans(current)
    if(current)
      return(false)
    endif()
    return(true)

  endfunction()





  function(token_stream_move_next stream)
    map_get(${stream}  current)
    ans(current)
    map_tryget(${current}  next)
    ans(next)
    map_set(${stream} current ${next})
   # message(FORMAT "moved from {current.data} to {next.data}")
  endfunction()





  function(token_stream_new language str)
    map_get(${language}  token_definitions)
    ans(token_definitions)
   # messagE("new token strean ${token_definitions}")

    #address_print(${language})

    tokens_parse("${token_definitions}" "${str}")
    ans(tokens)
    map_new()
    ans(stream)
    map_set(${stream} current ${tokens})
    stack_new()
    ans(stack)
    map_set(${stream} stack ${stack})
    map_set(${stream} first ${tokens})
    return_ref(stream)
  endfunction()






  function(token_stream_pop stream)
    map_get(${stream}  stack)
    ans(stack)
    stack_pop(${stack})
    ans(current)
    map_set(${stream} current ${current})
  #  message(FORMAT "popped to {current.data}")
  endfunction()





  function(token_stream_push stream)
    map_get(${stream}  stack)
    ans(stack)
    map_tryget(${stream}  current)
    ans(current)
    stack_push(${stack} ${current})

   # message("pushed")
  endfunction()





  function(token_stream_take stream token_definition)
   # message(FORMAT "trying to take {token_def_or_name.name}")
    map_tryget(${stream}  current)
    ans(current)
    if(NOT current)
      return()
    endif()
#    message(FORMAT "current token '{current.data}'  is a {current.definition.name}, expected {definition.name}")
    
    map_tryget(${current}  definition)
    ans(definition)
    
    if(${definition} STREQUAL ${token_definition})
   
      map_tryget(${current}  next)
      ans(next)
      map_set_hidden(${stream} current ${next})
      return(${current})
    endif()
    return()
  endfunction()






  function(cache_clear cache_key)
    memory_cache_clear("${cache_key}")
    file_cache_clear("${cache_key}")

  endfunction()






  function(cache_exists cache_key)
    memory_cache_exists("${cache_key}")
    ans(res)
    if(res)
      return_ref(res)
    endif()
    file_cache_exists("${cache_key}")
    ans(res)
    return_ref(res)
  endfunction()






  function(cache_get cache_key)
    memory_cache_get("${cache_key}")
    ans(res)
    if(res)
      return_ref(res)
    endif()
    file_cache_get("${cache_key}")
    ans(res)
    if(res)
      memory_cache_update("${cache_key}" "${res}")
      return_ref(res)
    endif()
  endfunction()





macro(cache_return_hit cache_key)
  cache_get("${cache_key}")
  ans(__cache_return)
  if(__cache_return)
    return_ref(__cache_return)
  endif()
endmacro()







  function(cache_update cache_key value)
    memory_cache_update("${cache_key}" "${value}" ${ARGN})
    file_cache_update("${cache_key}" "${value}" ${ARGN})
  endfunction()






  function(cached retrieve refresh compute_key)
    set(args ${ARGN})
    list_extract_flag(args --refresh)
    ans(refresh_cache)

    if(compute_key STREQUAL "")
      string_combine("_" ${args})
      ans(cache_key)
      string(MD5 "${cache_key}" cache_key)
    else()
      call("${compute_key}"(${args}))
      ans(cache_key)
    endif()
    
    cmakepp_config(temp_dir)
    ans(temp_dir)

    set(cache_dir "${temp_dir}/dir_cache/${cache_key}")
    if(EXISTS "${cache_dir}" NOT refresh_cache)
      call("${retrieve}"(args))
      return_ans()
    endif()

    pushd("${cache_dir}" --create)
    call("${refresh}"(args))
    ans(result)
    popd()

    if(NOT result)
      rm("${cache_dir}")
      return()
    endif()

    call("${retrieve}"(args))
    ans(result)

    return_ref(result)
  endfunction()






function(file_cache_clear cache_key)
  file_cache_key("${cache_key}")
  ans(path)
  if(EXISTS "${path}")
    file(REMOVE "${path}")
  endif()
  return()
endfunction()





function(file_cache_clear_all)
  cmakepp_config(temp_dir)
  ans(temp_dir)
  file(REMOVE_RECURSE "${temp_dir}/file_cache")
endfunction()






function(file_cache_exists cache_key)
  file_cache_key("${cache_key}")
  ans(path)
  if(EXISTS "${path}")
    return(true)
  endif()
  return(false)
endfunction()






function(file_cache_get cache_key)
  file_cache_key("${cache_key}")
  ans(path)
  if(EXISTS "${path}")
    qm_deserialize_file("${path}")
    return_ans()
  endif()
  return()
endfunction()





function(file_cache_key cache_key)
  is_address("${cache_key}")
  ans(isref)
  if(isref)
    json("${cache_key}")
    ans(cache_key)
  endif()
  checksum_string("${cache_key}")
  ans(key)
  cmakepp_config(cache_dir)
  ans(temp_dir)
  set(file "${temp_dir}/file_cache/_${key}.cmake")
  return_ref(file)
endfunction()






macro(file_cache_return_hit cache_key)
  file_cache_get("${cache_key}")
  ans(__cache_return)
  if(__cache_return)
    return_ref(__cache_return)
  endif()

endmacro()






function(file_cache_update cache_key)
  file_cache_key("${cache_key}")
  ans(path)
  qm_serialize("${ARGN}")
  ans(ser)
  file(WRITE "${path}" "${ser}")
  return()  
endfunction()






function(memory_cache_clear cache_key)
  memory_cache_key("${cache_key}")
  ans(key)
  map_set_hidden(memory_cache_entries "${key}")
  return()
endfunction()




function(memory_cache_exists cache_key)
  memory_cache_key("${cache_key}")
  ans(key)
  map_tryget(memory_cache_entries "${key}")
  ans(entry)
  if(entry)
    return(true)
  endif()
  return(false)
endfunction()






  function(memory_cache_get cache_key)
    set(args ${ARGN})
    list_extract_flag(args --const)
    ans(isConst)

    memory_cache_key("${cache_key}")
    ans(key)
    map_tryget(memory_cache_entries "${key}")
    ans(value)
    if(NOT isConst)
      map_clone_deep("${value}")
      ans(value)
    endif()
#    
    return_ref(value)
  endfunction()


  





  function(memory_cache_key cache_key)
    is_address("${cache_key}")
    ans(isref)
    if(isref)
      json("${cache_key}")
      ans(cache_key)
    endif()
 #  message("ck ${cache_key}")
    return_ref(cache_key)
  endfunction()





macro(memory_cache_return_hit cache_key)
  memory_cache_get("${cache_key}")
  ans(__cache_return)
  if(__cache_return)
    return_ref(__cache_return)
  endif()
endmacro()






  function(memory_cache_update cache_key value)
    set(args ${ARGN})
    list_extract_flag(args --const)
    ans(isConst)
    if(NOT isConst)
        map_clone_deep("${value}")
        ans(value)
    endif()

    memory_cache_key("${cache_key}")
    ans(key)
    
    map_set_hidden(memory_cache_entries "${key}" "${value}")
  endfunction()




function(string_cache_get cache_location key)
  string_cache_location("${cache_location}" "${key}")
  ans(location)
  if(NOT EXISTS "${location}")
    return()
  endif()
  fread("${location}/value.txt")
  return_ans()
endfunction()






function(string_cache_hit cache_location key)
  string_cache_location("${cache_location}" "${key}")
  ans(location)
  return_truth(EXISTS "${location}")
endfunction()





function(string_cache_location cache_location key)
  cmakepp_config(cache_dir)
  ans(cache_dir)
  path_qualify_from("${cache_dir}" "${cache_location}/${key}")
  ans(location)
  return_ref(location)
endfunction()





macro(string_cache_return_hit cache_location key)
  string_cache_hit("${cache_location}" "${key}")
  ans(hit)
  if( hit)
    string_cache_get("${cache_location}" "${key}")
    return_ans()
  endif()
endmacro()  






function(string_cache_update cache_location key value)
  string_cache_location("${cache_location}" "${key}")
  ans(location)
  if(NOT EXISTS "${location}")
    fwrite("${location}/value.txt" "${value}")
    return(true)
  else()
    fwrite("${location}/value.txt" "${value}")
    return(false)
  endif()
endfunction()





## `(<direcotry> [--algorthm <checksum algorithm> = "MD5"])-><checksum>`
##
## calculates the checksum for the specified directory 
## just like checksum_layout however also factors in the file's contents
## 
  function(checksum_dir dir)
    set(args ${ARGN})
    list_extract_labelled_keyvalue(args --algorithm)
    ans(algorithm)

    path_qualify(dir)

    file(GLOB_RECURSE files RELATIVE "${dir}" "${dir}/**")
    checksum_files("${dir}" ${files} ${algorithm})
    return_ans()
  endfunction()





## `(<file> [--algorithm <checksum algorithm> = "MD5"])-><checksum>`
##
## calculates the checksum for the specified file delegates the
## call to `CMake`'s file(<algorithm>) function
## 
function(checksum_file file)

  path_qualify(file)

  set(args ${ARGN})
  list_extract_labelled_value(args --algorithm)
  ans(checksum_alg)
  if(NOT checksum_alg)
    set(checksum_alg MD5)
  endif()
  file(${checksum_alg} "${file}" checksum)
  return_ref(checksum)
endfunction()







## `(<base dir> <file...>)-><checksum>`
##
## create a checksum from specified files relative to <dir>
## the checksum is influenced by the files relative paths 
## and the file content 
## 
function(checksum_files dir)
  set(args ${ARGN})
  list_extract_labelled_keyvalue(args --algorithm)
  ans(algorithm)

  list(LENGTH args len)
  if(len)
    list(REMOVE_DUPLICATES args)
    list(SORT args)
  endif()
  
  set(checksums)
  foreach(file ${ARGN})
    if(EXISTS "${dir}/${file}")
      checksum_file("${dir}/${file}" ${algorithm})
      ans(file_checksum)
      # create checksum from file checsum and file name
      checksum_string("${file_checksum}.${file}" ${algorithm})
      ans(combined_checksum)
      list(APPEND checksums "${combined_checksum}")
    endif()
  endforeach()

  checksum_string("${checksums}" ${checksum_alg})
  ans(checksum_dir)
  return_ref(checksum_dir)
endfunction()




## `(<glob ignore expressions...> [--algorithm <hash algorithm> = "MD5"])-><checksum>`
## 
## calculates the checksum for the specified glob ignore expressIONS
## uses checksum_files internally. the checksum is unique to file content
## and relative file structure
## 
function(checksum_glob_ignore)
    set(args ${ARGN})
    list_extract_labelled_keyvalue(args --algorithm)
    ans(algorithm)
    glob_ignore(${args} --recurse ${algorithm})
    ans(files)


    pwd()
    ans(pwd)
    set(normalized_files)
    foreach(file ${files})
        path_qualify(file)
        path_relative("${pwd}" "${file}")
        ans(file)
        list(APPEND normalized_files ${file})      
    endforeach()



    checksum_files("${pwd}" ${normalized_files})
    return_ans()
endfunction()




## `(<directory> [--algorithm <hash algorithm> "MD5"])-><checksum>`
## 
## this method generates the checksum for the specified directory
## it is done by taking every file's relative path into consideration
## and generating the hash.  The file's content does not influence the hash
## 
function(checksum_layout dir)
    path_qualify(dir)

    set(args ${ARGN})

    list_extract_labelled_keyvalue(args --algorithm)
    ans(algorithm)

    file(GLOB_RECURSE files RELATIVE "${dir}" "${dir}/**")

    if(files)
        ## todo sort. normalize paths, remove directories
        string(REPLACE "//" "/" files "${files}")
        list(SORT files)
    endif()
    
    checksum_string("${files}" ${algorithm})
    ans(checksum_dir)

    return_ref(checksum_dir)
endfunction()






## `(<any> [--algorithm <hash algorithm> = "MD5"])-><checksum>`
##
## this function takes any value and generates its hash
## the difference to string hash is that it serializes the specified object 
## which lets you create the hash for the whoile object graph.  
## 
function(checksum_object obj)
  json("${obj}")
  ans(json)
  checksum_string("${json}" ${ARGN})
  return_ans()
endfunction()




## `(<string> [--algorithm <hash algorithm> = MD5])-><checksum>`
## `<hash algorithm> ::= "MD5"|"SHA1"|"SHA224"|"SHA256"|"SHA384"|"SHA512"`
##
## this function takes any string and computes the hash value of it using the 
## hash algorithm specified (which defaults to  MD5)
## returns the checksum
## 
function(checksum_string str)
  set(args ${ARGN})
  list_extract_labelled_value(args --algorithm)
  ans(algorithm)
  if(NOT algorithm)
    set(algorithm MD5)
  endif()
  string("${algorithm}"  checksum "${str}" )
  return_ref(checksum)
endfunction()




function(Object)
	#formats the current object 
	proto_declarefunction(to_string)

	function(${to_string} )
		set(res)
#		debug_message("to_string object ${this}")
		obj_keys(${this} keys)

		foreach(key ${keys})
			obj_get(${this}  ${key})				
			ans(value)
			map_has(${this}  ${key})
			ans(is_own)	
			if(value)
				is_function(function_found ${value})
				is_object(object_found ${value})
			endif()
			
			
			if(function_found)
				set(value "[function]")
			elseif(object_found)
				get_filename_component(fn ${value} NAME_WE)
				obj_gettype(${value} )
				ans(type)
				if(NOT type)
					set(type "")
				endif()
				set(value "[object ${type}:${fn}]")
			else()
				set(value "\"${value}\"")
			endif()
			if(is_own)
				set(is_own "*")
			else()
				set(is_own " ")
			endif()

			set(nextValue "${is_own}${key}: ${value}")

			if(res)
				set(res "${res}\n ${nextValue}, ")	
			else()
				set(res " ${nextValue}, ")
			endif()
		endforeach()

		set(res "{\n${res}\n}")
		return_ref(res)
	endfunction()

	# prints the current object to the console
	proto_declarefunction(print)
	function(${print})
		#debug_message("printing object ${this}")
		obj_member_call(${this} "to_string" str )
		message("${str}")
	endfunction()
endfunction()







## `(<ast: <cmake code> |<cmake ast>>)-><cmake ast>`
##
## tries to parse the cmake code to an ast or returns the existign ast
function(cmake_ast ast)
  is_address("${ast}")
  ans(isref)
  if(NOT isref)
    cmake_ast_parse("${ast}")
    ans(ast)
  endif()
  return_ref(ast)
endfunction()






function(cmake_ast_function_parse target end)
  map_tryget(${end} value)
  ans(value)
  
  if(NOT "${value}" MATCHES "^(endfunction)|(endmacro)$")
    return()
  endif()
  map_tryget(${end} invocation_nesting_begin)
  ans(begin)

  map_tryget(${begin} value)
  ans(command_type)


  ## get name token and name
  cmake_token_range_find_next_by_type(${begin} "(unquoted_argument)|(quoated_argument)")
  ans(name_token)
  map_tryget(${name_token} literal_value)
  ans(name)

  ## next after name is the beginning of the signature
  map_tryget(${name_token} next)
  ans(signature_begin)

  ## next->end is the closing parentheses
  map_tryget(${begin} next)
  ans(parens)
  map_tryget(${parens} end)
  ans(signature_end) ## the closing paren

  ## get the beginning and end of the body
  ## body begins directly after signature
  map_tryget(${signature_end} next)
  ans(body_begin)

  ## body ends directly before endfunction/endmacro
  set(body_end ${end})
  

  ## set the extracted vars
  map_set(${begin} command_type "${command_type}")  
  map_set(${begin} invocation_type command_definition)
  map_set(${begin} name_token ${name_token})
  map_set(${begin} name "${name}")
  map_set(${begin} signature_begin ${signature_begin})
  map_set(${begin} signature_end ${signature_end})
  map_set(${begin} body_begin ${body_begin}) 
  map_set(${begin} body_end ${body_end})

  ## 
  map_append(${target} command_definitions ${begin})
  map_set(${target} "command-${name}" ${begin})
  return_ref(begin)

endfunction()





## `()->{ <<identifier open>:<identifier close>...>... }`
##
## returns a map which contains all nesting pairs in cmake
function(cmake_ast_nesting_pairs)
  map_new()
  ans(nesting_start_end_pairs)
  map_set(${nesting_start_end_pairs} function endfunction)
  map_set(${nesting_start_end_pairs} while endwhile)
  map_set(${nesting_start_end_pairs} if elseif else endif)
  map_set(${nesting_start_end_pairs} elseif elseif else endif)
  map_set(${nesting_start_end_pairs} else endif)
  map_set(${nesting_start_end_pairs} macro endmacro)
  map_set(${nesting_start_end_pairs} foreach endforeach)
 
 return_ref(nesting_start_end_pairs)
endfunction()




## `(<code:<cmake code>|<cmake token...>>)-><cmake ast>`
##
## generates the an ast for the cmake code 
function(cmake_ast_parse code)
  cmake_ast_nesting_pairs()
  ans(nesting_start_end_pairs)
  
  map_values(${nesting_start_end_pairs})
  ans(endings)
  map_keys(${nesting_start_end_pairs})
  ans(openings)
  list_remove_duplicates(endings)

  cmake_tokens("${code}")
  ans(tokens)

  ans_extract(current_invocation)

  map_new()
  ans(ast)

  map_set(${ast} tokens ${tokens})

  ## push the first nesting on the nestings stack
  set(nestings "${ast}")
  set(current_nesting ${ast})

  while(true)
    cmake_token_range_find_next_by_type("${current_invocation}" command_invocation)
    ans(current_invocation)
    if(NOT current_invocation)
      break()
    endif()
    
    
    map_append(${current_nesting} command_invocations ${current_invocation})
    map_tryget(${current_invocation} value)
    ans(invocation_value)

    list_contains(openings ${invocation_value})
    ans(is_opening)
    list_contains(endings ${invocation_value})
    ans(is_closing)

    ## handles the closing of an invocation nesting
    if(is_closing)
      set(begin "${current_nesting}")
      set(end "${current_invocation}")

      ## pop the top nesting
      list(REMOVE_AT nestings 0)
      list(GET nestings 0 current_nesting)

      if("${begin}" STREQUAL "${root_nesting}")  
        message(FORMAT "unbalanced code nesting for {current_invocation.value} @{current_invocation.line}:{current_invocation.column}")
        error( "unbalanced code nesting for {current_invocation.value} @{current_invocation.line}:{current_invocation.column}")
        return()
      endif()


      map_tryget(${begin} value)
      ans(begin_value)
      set(end_value ${invocation_value})

      map_tryget(${nesting_start_end_pairs} ${begin_value})
      ans(current_closings)
      
      list_contains(current_closings ${end_value})
      ans(correct_closing)
      if(NOT correct_closing)
        message(FORMAT "invalid closing for opening '{current_nesting.value}' @{current_nesting.line}:{current_nesting.column}: '{current_invocation.value}' @{current_invocation.line}:{current_invocation.column}")
        error("invalid closing for {current_invocation.value} @{current_invocation.line}:{current_invocation.column}")
        return()
      endif()
            
      map_set(${begin} invocation_nesting_end ${end})
      map_set(${end} invocation_nesting_begin ${begin})
    endif()
    list(LENGTH nestings nesting_depth)
    math(EXPR nesting_depth "${nesting_depth} - 1")
    map_set(${current_invocation} invocation_nesting_depth ${nesting_depth})
    cmake_ast_function_parse("${current_nesting}" "${current_invocation}")
    cmake_ast_variable_parse("${current_nesting}" "${current_invocation}")
    map_append(${current_nesting} children ${current_invocation})

    ## handles the opening of an invocation nesting
    if(is_opening)
      ## push the the current_invocation nesting
      list(INSERT nestings 0 ${current_invocation})
      set(current_nesting ${current_invocation})
    endif()

    map_tryget(${current_invocation} next)
    ans(current_invocation)
  endwhile()

  return_ref(ast)
endfunction()





  function(cmake_ast_serialize ast)
    cmake_ast("${ast}")
    ans(ast)
    assign(start = ast.tokens[0])
    assign(end = ast.tokens[$])
    cmake_token_range_serialize("${start};${end}")
    return_ans()
  endfunction()







function(cmake_ast_variable_parse target invocation_token)
  map_tryget(${invocation_token} value)
  ans(value)
  if(NOT "${value}" STREQUAL "set")
    return()
  endif()
  ## get first name token inside invocation_token
  cmake_token_range_find_next_by_type(${invocation_token} "(unquoted_argument)|(quoated_argument)")
  ans(name_token)

  ## get the value of the name token
  map_tryget(${name_token} literal_value)
  ans(name)

  ## get the beginning of values 
  ## the first token after name 
  map_tryget(${name_token} next)
  ans(values_begin)
  ## get the ending of values
  ## the ) 
  cmake_token_range_find_next_by_type(${invocation_token} "(nesting)")
  ans(nesting)
  map_tryget(${nesting} end)
  ans(values_end)
  
  ## set the values
  map_set(${invocation_token} invocation_type variable)
  map_set(${invocation_token} name_token ${name_token})
  map_set(${invocation_token} name ${name})
  map_set(${invocation_token} values_begin ${values_begin})
  map_set(${invocation_token} values_end ${values_end})


  ## add the the variables to the target map
  map_append(${target} variables ${invocation_token})
  map_set(${target} "variable-${name}" ${invocation_token})
endfunction()




## `([-v])-><any...>`
##
## the comand line interface to cmakelists.  tries to find the CMakelists.txt in current or parent directories
## if init is specified a new cmakelists file is created in the current directory
## *flags*:
##  * 
## *commands*:
##  * `init` saves an initial cmake file at the current location
##  * `target <target name> <target command> | "add" <target name>` target commands:
##    * `add` adds the specified target to the end of the cmakelists file
##    * `sources "append"|"set"|"remove" <glob expression>...` adds appends,sets, removes the source files specified by glob expressions to the specified target
##    * `includes "append"|"set"|"remove" <path>....` adds the specified directories to the target_include_directories of the specified target
##    * `links "append"|"set"|"remove" <target name>...` adds the specified target names to the target_link_libraries of the specified target
##    * `type <target type>` sets the type of the specified target to the specified target type
##    * `rename <target name>` renames the specified target 
## 
## `<target type> ::= "library"|"executable"|"custom_target"|"test"`  
function(cmakelists_cli)
  set(args ${ARGN})
  list_pop_front(args)
  ans(command)

  list_extract_flags(args -v)
  ans(verbose)

  set(handler)
  if(verbose)
    event_addhandler(on_log_message "[](entry) message(FORMAT '{entry.function}: {entry.message}') ")
  endif()
  cmakelists_open("")
  ans(cmakelists)

  if(NOT cmakelists AND "${command}" STREQUAL "init")
    path_parent_dir_name(CMakeLists.txt)
    ans(project_name)
    cmakelists_new("cmake_minimum_required(VERSION ${CMAKE_VERSION})\n\nproject(${project_name})\n\n")
    ans(cmakelists)
  elseif(NOT cmakelists)
    error("no CMakeLists.txt file found in current or parent directories" --function cmakelists_cli)
    return()
  elseif("${command}" STREQUAL "init")
    cmakelists_new("cmake_minimum_required(VERSION ${CMAKE_VERSION})")
    ans(cmakelists)
  endif()

  
  set(save false)
  if("${command}" STREQUAL "init")
    set(save true)
  elseif("${command}" STREQUAL "target")
    list_pop_front(args)
    ans(target_name)

    list_pop_front(args)
    ans(command)

    if("${target_name}" STREQUAL "add")
      set(target_name "${command}")
      set(command add)
    endif()

    if(NOT command)
      cmakelists_targets(${cmakelists} ${target_name})
      ans(result)
    elseif("${command}" STREQUAL "rename")
      list_pop_front(args)
      ans(name)
      cmakelists_target(${cmakelists} "${target_name}")
      ans(target)
      if(NOT target)
          message(FATAL_ERROR FORMAT "no single target found for ${target_name} in {cmakelists.path}")
      endif()
      map_set(${target} target_name "${name}")
      cmakelists_target_update("${cmakelists}" "${target}")
      set(save true)
      set(result ${target})

    elseif("${command}" STREQUAL "type")
      list_pop_front(args)
      ans(type)
      cmakelists_target(${cmakelists} "${target_name}")
      ans(target)
      if(NOT target)
          message(FATAL_ERROR "no single target found for ${target_name}")
      endif()
      map_set(${target} target_type "${type}")
      cmakelists_target_update("${cmakelists}" "${target}")
      set(save true)
      set(result ${target})

    elseif("${command}" STREQUAL add)
      list_extract(args target_type)
      set(save true)
      if(NOT target_type)
          set(target_type library)
      endif()
      map_capture_new(target_name target_type)
      ans(result)
      cmakelists_target_update(${cmakelists} ${result})
    elseif("${command}" STREQUAL "includes")
      cmakelists_target(${cmakelists} "${target_name}")
      ans(target)
      if(NOT target)
          message(FATAL_ERROR "no single target found for ${target_name}")
      endif()

      list_pop_front(args)
      ans(command)

      map_tryget(${target} target_include_directories)
      ans(result)
      if(command)
          set(flag "--${command}")
          set(before ${result})
          cmakelists_paths("${cmakelists}" ${args})
          ans(args)
          list_modify(result ${flag} --remove-duplicates --sort ${args})
          set(save true) 
          map_set(${target} target_include_directories PUBLIC ${result})
          cmakelists_target_update(${cmakelists} ${target})
      endif()
    elseif("${command}" STREQUAL "links")
      cmakelists_target(${cmakelists} "${target_name}")
      ans(target)
      if(NOT target)
          message(FATAL_ERROR "no single target found for ${target_name}")
      endif()

      list_pop_front(args)
      ans(command)

      map_tryget(${target} target_link_libraries)
      ans(result)
      if(command)
          set(flag "--${command}")
          set(before ${result})
          list_modify(result ${flag} --remove-duplicates ${args})

          set(save true)
          map_set(${target} target_link_libraries ${result})
          cmakelists_target_update(${cmakelists} ${target})
                          
      endif()
    elseif("${command}" STREQUAL "sources")

      cmakelists_target(${cmakelists} "${target_name}")
      ans(target)
      if(NOT target)
          message(FATAL_ERROR "no single target found for ${target_name}")
      endif()

      list_pop_front(args )
      ans(command)

      map_tryget(${target} target_source_files)
      ans(result)
      if(command)
          set(flag "--${command}")
          set(before ${result})
          cmakelists_paths(${cmakelists} ${args} --glob)
          ans(args)
          list_modify(result ${flag} --remove-duplicates ${args})

          set(save true)
          map_set(${target} target_source_files ${result})
          cmakelists_target_update(${cmakelists} ${target})
                          
      endif()

    endif()

  endif()

  if(save)

    cmakelists_close(${cmakelists})
  endif()
  return_ref(result)
endfunction()




function(cmakelists_target_modify cmakelists target target_property)
  set(args ${ARGN})
  cmakelists_target("${cmakelists}" "${target}")
  ans(target)
  if(NOT target)
    return()
  endif()
  
  list_pop_front(args)
  ans(command)

  map_tryget(${target} "${target_property}")
  ans(result)
  
  if(command)
    set(flag "--${command}")
    list_modify(result ${flag} --remove-duplicates ${args})
    print_vars(result command args target.target_name target_property)
    map_set(${target} "${target_property}" ${result})
    cmakelists_target_update(${cmakelists} ${target})
  endif()        
  return_ref(result)
endfunction()




## `(<cmakelists>)-> <bool>`
##
## closes the specified cmakelists file.  This causes it to be written to its path
## returns true on success
function(cmakelists_close cmakelists) 
  map_tryget(${cmakelists} path)
  ans(cmakelists_path)
  cmakelists_serialize("${cmakelists}")
  ans(content)
  fwrite("${cmakelists_path}" "${content}")
  return(true)
endfunction()




  function(cmakelists_new source)
    set(cmakelists_path "${ARGN}")
    if(NOT cmakelists_path)
        set(cmakelists_path .)
    endif()
    if(NOT "${cmakelists_path}" MATCHES "CMakeLists\\.txt$")
        set(cmakelists_path "${cmakelists_path}/CMakeLists.txt")
    endif()
    path_qualify(cmakelists_path)

    map_new()
    ans(cmakelists)

    cmake_token_range("${source}")

    ans_extract(begin end)    
    map_set(${cmakelists} begin ${begin})
    map_set(${cmakelists} end ${end} )
    map_set(${cmakelists} range ${begin} ${end})
    map_set(${cmakelists} path "${cmakelists_path}")

    return_ref(cmakelists)
  endfunction()





## `([<path>])-><cmakelists>|<null>`
##
## opens a the closests cmakelists file (anchor file) found in current or parent directory
## returns nothing if no cmakelists file is found. 
function(cmakelists_open)
  file_find_anchor("CMakeLists.txt" ${ARGN})
  ans(cmakelists_path)
  if(NOT cmakelists_path)
    return()
  else()
    fread("${cmakelists_path}")
    ans(content)
  endif()
  cmakelists_new("${content}" "${cmakelists_path}")
  return_ans()
endfunction()




## `(<cmakelists> <file>... [--glob] )-> <relative path>...`
##
## qualifies the paths relative to the cmakelists directory 
## if `--glob` is specified then the `<file>...` will be treated
## as glob expressions
function(cmakelists_paths cmakelists)
  set(args ${ARGN})
  list_extract_flag(args --glob)
  ans(glob)

  map_tryget(${cmakelists} path)
  ans(cmakelists_path)
  path_parent_dir("${cmakelists_path}")
  ans(cmakelists_dir)
  set(files)

  if(glob)
    glob(${args})
    ans(args)
  else()
    paths(${args})
    ans(args)
  endif()
  foreach(file ${args})
    path_relative("${cmakelists_dir}" "${file}")
    ans_append(files)
  endforeach()
  return_ref(files)

endfunction()





## `(<cmakelists>)-> <cmake code>`
##
## serializes the specified cmakelists into its textual representation.
function(cmakelists_serialize cmakelists)
  map_tryget(${cmakelists} begin)
  ans(begin)
  cmake_token_range_serialize("${begin}")
  ans(content)
  return_ref(content)
endfunction()





## `(<cmakelists> <target:<target name regex>|<cmake target>)-><cmake target> v {target_invocations: <target invocations>}`
##
## tries to find the single target identified by the regex and returns it. 
## 
## ```
## <target> ::= {
##    target_name: <string>
##    target_type: "library"|"executable"|"test"|"custom_target"|...
##    target_source_files
##    target_include_directories
##    target_link_libraries
##    target_compile_definitions
##    target_compile_options
## }
## ```
function(cmakelists_target cmakelists target)
  is_address("${target}")
  ans(is_ref)
  if(is_ref)
    return(${target})
  endif()
  set(target_name ${target})
  cmakelists_targets("${cmakelists}" "${target_name}")
  ans(targets)
  map_values(${targets})
  ans(target)
  list(LENGTH target count)
  if(NOT "${count}" EQUAL 1)
    error("could not find single target (found {count})")
    return()
  endif()
  return_ref(target)
endfunction()





## `(target_name:<regex>)-><cmake target>`
##
## returns all targets whose name match the specified regular expression
function(cmakelists_targets cmakelists target_name )
  map_tryget(${cmakelists} range)
  ans(range)
  cmake_token_range_targets_filter("${range}" "${target_name}")
  return_ans()
endfunction()




## `(<cmakelists> <cmake target>)-><bool>`
## 
## updates the cmakelists tokens to reflect changes in the target
## @todo extrac functions
## 
function(cmakelists_target_update cmakelists target)
  cmakelists_target("${cmakelists}" "${target}")
  ans(target)
  if(NOT target)
    return(false)
  endif()

  map_tryget(${target} target_invocations)
  ans(target_invocations)

  map_tryget(${target} target_name)
  ans(target_name)
  if(NOT target_name)
    error("target name not specified" --function cmakelists_target_update)
    return(false)
  endif()
  
  map_tryget(${target} target_type)
  ans(target_type)

  ## target does not exist. create
  if(NOT target_invocations)
    log("adding target ${target_name} (${target_type}) to end of cmakelists file" --trace --function cmakelists_target_update)
    ## find insertion point
    map_tryget(${cmakelists} range)
    ans_extract(begin end)

    cmake_token_range_insert("${end}" "\nadd_${target_type}(${target_name})\n")
    cmakelists_target("${cmakelists}" "${target_name}")
    ans(new_target)


    map_defaults("${target}" "${new_target}")
    map_tryget(${new_target} target_invocations)
    ans(target_invocations)
    map_set_hidden(${target} target_invocations ${target_invocations})
    
  endif()

  ## sets the target type  
  map_tryget(${target_invocations} target_source_files)
  ans(target_definition_invocation)
  map_tryget(${target_definition_invocation} invocation_token)
  ans(target_definition_invocation_token)
  map_set("${target_definition_invocation_token}" value "add_${target_type}")


  map_tryget(${target_definition_invocation_token} column)
  ans(insertion_column)
  string_repeat(" " ${insertion_column})
  ans(indentation)



  foreach(current_property 
    target_source_files 
    target_link_libraries 
    target_include_directories 
    target_compile_options
    target_compile_definitions
    )


    map_tryget(${target} "${current_property}")
    ans(values)
    map_tryget(${target_invocations} "${current_property}")
    ans(invocation)
    list(LENGTH values has_values)
    if(has_values)
      if(NOT invocation)
        log("adding ${current_property} for ${target_name}" --trace --function cmakelists_target_update)
        map_tryget(${target_definition_invocation} arguments_end_token)
        ans(insertion_point)
        cmake_token_range_filter("${insertion_point}" type MATCHES "(new_line)|(eof)")
        ans_extract(insertion_point)         
        cmake_token_range_insert("${insertion_point}" "\n${indentation}${current_property}()")
        ans_extract(invocation_token)
        cmake_token_range_filter("${invocation_token}" type STREQUAL "command_invocation")
        ans_extract(invocation_token)
        map_set("${invocation_token}" "column" ${insertion_column})
      else()
        log("updating ${current_property} for ${target_name} to '${values}'" --trace --function cmakelists_target_update)
        map_tryget(${invocation} invocation_token)
        ans(invocation_token)
      endif()
      cmake_invocation_token_set_arguments("${invocation_token}" "${target_name}" ${values})

    elseif(invocation AND NOT "${current_property}"  STREQUAL "target_source_files")
      log("removing ${current_property} for ${target_name}" --trace --function cmakelists_target_update)
      ## remove invocation
      map_remove("${target_invocations}" "${current_property}")
      cmake_invocation_remove("${invocation}")
    endif()

  endforeach()    
  return(true)
endfunction()




## `(<cmakelists> <variable path>)-><any>...`
## 
## see list_modify
## modifies a variable returns the value of the variable
function(cmakelists_variable cmakelists variable_path)
  map_tryget(${cmakelists} begin)
  ans(range)
  cmake_token_range_variable_navigate("${range}" "${variable_path}" ${ARGN})
  return_ans()
endfunction()




## `(...)->...`
## 
## wrapper for cmakelists_cli
function(cml)
  set(args ${ARGN})
  cmakelists_cli(${args})
  ans(res)
  return_ref(res)
endfunction()





## `(<any>...)-><cmake escaped>...`
##
## quotes all arguments which need quoting ## todo allpw encoded lists
function(cmake_arguments_quote_if_necessary)
  regex_cmake()
  set(result)
  foreach(arg ${ARGN})
    if("${arg}" MATCHES "${regex_cmake_value_needs_quotes}")
      string(REGEX REPLACE 
        "${regex_cmake_value_quote_escape_chars}" 
        "\\\\\\0" #prepends a '\' before each matched cahr 
        arg "${arg}"
        )
      set(arg "\"${arg}\"")
    endif()

    list(APPEND result "${arg}")
  endforeach()
  return_ref(result)
endfunction()




## `()-> <environment>`
##
## ```
## <environment descriptor> ::= {
##  host_name: <string> # Computer Name
##  processor: <string> # processor identification string
##  architecture: "32"|"64" # processor architecture
##  os:<operating system descriptor>
## }
## <operating system descriptor> ::= {
##  name: <string>
##  version: <string>
##  family: "Windows"|"Unix"|"MacOS"|...  
## }
## ```
## 
## returns the environment of cmake
## the results are cached (--update-cache if necesssary)
function(cmake_environment)
  function(_cmake_environment_inner)
    pushtmp()
    cmakepp_config(cmakepp_path)
    ans(cmakepp_path)
      path("output.qm")
      ans(output_file)
      fwrite("CMakeLists.txt" "
        cmake_minimum_required(VERSION 2.8.12)
        include(${cmakepp_path})
        #get_cmake_property(_cmake_variables VARIABLES)
        set(vars 
          CMAKE_GENERATOR
          CMAKE_SIZEOF_VOID_P
          CMAKE_SYSTEM
          CMAKE_SYSTEM_NAME
          CMAKE_SYSTEM_PROCESSOR
          CMAKE_SYSTEM_VERSION
          CMAKE_HOST_SYSTEM
          CMAKE_HOST_SYSTEM_NAME
          CMAKE_HOST_SYSTEM_PROCESSOR
          CMAKE_HOST_SYSTEM_VERSION
          CMAKE_C_COMPILER_ID
          CMAKE_CXX_COMPILER_ID
        )
        map_new()
        ans(result)
        foreach(var \${vars})
          map_set(\${result} \${var} \${\${var}})
        endforeach()
        cmake_write(\"${output_file}\" \"\${result}\")
      ")  


      pushd(build --create)
        cmake_lean("..")
        ans_extract(error)
        ans(stdout)
      popd()
    
    if(error)
      poptmp()
      message(FATAL_ERROR "${stdout}")
    endif()
    cmake_read(${output_file})
    ans(res)
    poptmp()
    set(result)
    
    site_name(host_name)
    assign(!result.host_name = host_name)     
    assign(!result.architecture = res.CMAKE_HOST_SYSTEM_PROCESSOR) 
    
  #  map_tryget(${res} CMAKE_SIZEOF_VOID_P)
   # ans(byte_size_voidp)
   # math(EXPR architecture "${byte_size_voidp} * 8")
   # assign(!result.architecture = architecture)
    
    assign(!result.os.name = res.CMAKE_HOST_SYSTEM_NAME)   
    assign(!result.os.version = res.CMAKE_HOST_SYSTEM_VERSION) 
    if(WIN32)
      assign(!result.os.family = 'Windows')   
    elseif(MAC)
      assign(!result.os.family = 'MacOS')   
    elseif(UNIX)
      assign(!result.os.family = 'Unix')  
    endif()
    return_ref(result)
  endfunction()
  
  define_cache_function(_cmake_environment_inner => cmake_environment
    --generate-key "[]()checksum_string({{CMAKE_COMMAND}})"
  )
  cmake_environment(${ARGN})
  return_ans()
endfunction()





## `()-> <string..>`
##
## returns a list of available generators on current system
function(cmake_generator_list)
  cmake_lean(--help)
  ans(help_text)
  list_pop_front(help_text)
  ans(error)
  if(error)
    message(FATAL_ERROR "could not execute cmake")
  endif()
  if("${help_text}" MATCHES "\nGenerators\n\n[^\n]*\n(.*)")
    set(generators_text "${CMAKE_MATCH_1}")
  endif()


  string(REGEX MATCHALL "(^|\n)  [^ \t][^=]*=" generators "${generators_text}")
  set(result)
  foreach(generator ${generators})
    if("${generator}" MATCHES "  ([^ ].*[^ \n])[ ]*=")
      set(generator "${CMAKE_MATCH_1}")
      list(APPEND result "${generator}")
    endif()

  endforeach()

  map_set(global cmake_generators "${result}")
  function(cmake_generators)
    map_tryget(global cmake_generators)
    return_ans()
  endfunction()

  cmake_generators()
  return_ans()
endfunction()




function(environment_processor_count)
  # from http://www.cmake.org/pipermail/cmake/2010-October/040122.html
  if(NOT DEFINED processor_count)
    # Unknown:
    set(processor_count 0)

    # Linux:
    set(cpuinfo_file "/proc/cpuinfo")
    if(EXISTS "${cpuinfo_file}")
      file(STRINGS "${cpuinfo_file}" procs REGEX "^processor.: [0-9]+$")
      list(LENGTH procs processor_count)
    endif()

    # Mac:
    if(APPLE)
      find_program(cmd_sys_pro "system_profiler")
      if(cmd_sys_pro)
        execute_process(COMMAND ${cmd_sys_pro} OUTPUT_VARIABLE info)
        string(REGEX REPLACE "^.*Total Number Of Cores: ([0-9]+).*$" "\\1" processor_count "${info}")
      endif()
    endif()

    # Windows:
    if(WIN32)
      set(processor_count "$ENV{NUMBER_OF_PROCESSORS}")
    endif()
  endif()

  eval("
  function(environment_processor_count)
    set(__ans ${processor_count} PARENT_SCOPE)
  endfunction()
  ")
  environment_processor_count()
  return_ans()
endfunction()




function(test)

  fwrite("include/lib1.h" "")
  fwrite("include/lib2.h" "")
  fwrite("include/lib3.h" "")
  fwrite("include/lib4.h" "")
  fwrite("src/main.cpp" "")
  fwrite("src/impl1.cpp" "")
  fwrite("src/impl2.cpp" "")
  fwrite("src/impl3.cpp" "")
  fwrite("src/dir1/impl4.cpp" "")
  fwrite("src/dir2/impl5.cpp" "")

  
endfunction()


function(generator_cmake_source_group name)
  set(globs ${ARGN})
  glob_ignore(${globs} --relative)
  ans(files)


  set(template "## 


    ")

endfunction()


function(generator_cmake_add_library config)



endfunction()






    function(is_cmake_function code) 
      if("${code}" MATCHES "function.*endfunction")
        return(true)
      endif()
      return(false)
    endfunction()





function(cmake_function_parse code)
  cmake_function_signature("${code}")
  ans(signature)
  map_set(${signature} code "${code}")
  return_ref()
endfunction()






    function(cmake_function_rename_first code new_name)
        cmake_function_signature("${code}")
        ans(sig)
        map_tryget(${sig} signature_code)
        ans(old_func)
        map_tryget(${sig} name)
        ans(old_name)
        string(REPLACE "${old_name}" "${new_name}" new_func "${old_func}")
        string(REPLACE "${old_func}" "${new_func}" code "${code}")
        return_ref(code)
    endfunction()






    function(cmake_function_signature code)
      regex_cmake()  
      string(REGEX MATCHALL "${regex_cmake_function_begin}" functions "${code}")
      list_pop_front(functions)
      ans(function)

      map_new()
      ans(res)
      if("${function}" MATCHES "${regex_cmake_function_signature}")
        map_set(${res} name "${${regex_cmake_function_signature.name}}")
        map_set(${res} args_string "${${regex_cmake_function_signature.args}}")
        map_set(${res} signature_code "${function}")
      endif()
      return_ref(res)
    endfunction()






    function(cmake_function_signatures code)
      regex_cmake()
      string(REGEX MATCHALL "${regex_cmake_function_begin}" functions "${code}")
      return_ref(functions)
    endfunction()







  function(cmake_script_comment_header content)
    set(args ${ARGN})
    list_extract_flag(args --depth)
    ans(expected_depth)
    if("${expected_depth}_" STREQUAL "")
      set(expected_depth 1)
    endif()

    string_repeat( "#" "${expected_depth}")
    ans(expected_depth)
    cmake_script_parse("${content}" --comment-header --ignore-newlines)
    ans(lines)
    set(markdown)
    foreach(line ${lines})
      map_tryget(${line} type)
      ans(type)
      
      if("${type}" STREQUAL "comment")
        map_tryget(${line} comment_depth)
        ans(depth)
        if("${depth}" STREQUAL "${expected_depth}")
          map_tryget("${line}" comment)
          ans(comment)
          set(markdown "${markdown}${comment}\n")
        else()
          break()
        endif()
      endif()
    endforeach()
    
    return_ref(markdown)  
  endfunction()





##
##
function(cmake_script_parse content)
  set(args ${ARGN})
  list_extract_flag(args --comment-header)
  ans(return_comment_header)
  list_extract_flag(args --ignore-newlines)
  ans(ignore_newlines)
  list_extract_flag(args --first-function-header)
  ans(return_first_function_header)
  set(res)  
  set(non_empty_script_found false)

  while(true)
    set(empty false)
    string_take_whitespace(content)
    string_take_regex(content "[^\n]+")
    ans(line)
    string_take_regex(content "\n")
    list(LENGTH content len)
   
    if(NOT len)
      break()
    endif()
    map_new()
    ans(current)
    map_set(${current} line "${line}")
    if("${line}" MATCHES "^(#+)(.*)")
      map_set(${current} type "comment")
      map_set(${current} comment "${CMAKE_MATCH_2}")
      map_set(${current} comment_depth "${CMAKE_MATCH_1}")
    else()
      map_set(${current} type "script")
      string_take_whitespace(line)
      if("${line}_" STREQUAL "_" )
        map_set(${current} empty true)
        set(empty true)
      else()
        map_set(${current} empty false)
        set(non_empty_script_found true)
        set(empty false)

        if(return_comment_header)
          return_ref(res)
        endif()
      endif()
      map_set(${current} script "${line}")
      set(CMAKE_MATCH_3)
      if("${line}" MATCHES "^([^\\(]+)(\\(.*\\))(.*)")
        map_set(${current} function_name "${CMAKE_MATCH_1}")   
        map_set(${current} function_call "${CMAKE_MATCH_2}")
        set(function_name "${CMAKE_MATCH_1}")
        set(function_call "${CMAKE_MATCH_2}")
        string(REGEX REPLACE "\\((.*)\\)" "\\1" function_call "${function_call}")
          while(true)
            string_take_whitespace(function_call)
            if("${function_call}_" STREQUAL "_")
              break()
            endif()
            ans(arg)
            if("${arg}_" STREQUAL "_")
              string_take_regex(function_call "[^ ]+")
              ans(arg)
            endif()
            string_encode_semicolon("${arg}")
            ans(arg)
            map_append(${current} function_args "${arg}")
         
          endwhile()
        if("${CMAKE_MATCH_3}" MATCHES "^[ ]*#(.*)[ ]*$")
          map_set(${current} comment "${CMAKE_MATCH_1}")
        endif()
        if(return_first_function_header AND ( "${function_name}" STREQUAL "function" OR "${function_name}" STREQUAL "macro"))
          return(${current})
        endif()
      endif()
    endif()
    if(NOT (empty AND ignore_newlines))
      list(APPEND res ${current})
    endif()
  endwhile()
  return_ref(res)
endfunction()







function(cmake_script_parse_file path)
  fread("${path}")
  ans(content)
  cmake_script_parse("${content}" ${ARGN})
  return_ans()
endfunction()




## `(<start:<token>> <end:<token>> [<limit:<uint>>])-><token>...` 
##
## returns the tokens which match type
## maximum tokens retunred is limit if specified
function(cmake_token_range_find_by_type start end type)
  set(limit ${ARGN})
  set(current ${start})
  set(count 0)
  set(result)
  while(current AND NOT "${current}" STREQUAL "${end}")
    if(limit AND NOT ${count} LESS "${limit}")
      return_ref(result)
    endif()
    map_tryget(${current} type)
    ans(current_type)

    if("${current_type}" MATCHES "${type}")
      list(APPEND result "${current}")
      math(EXPR count "${count} + 1")
    endif()
    map_tryget(${current} next)
    ans(current)
  endwhile()  
  return_ref(result)
endfunction()




## `(<token range> <identifier:<regex>>  [<limmit>:<uint>])-><command invocation...>`
##
## returns all invocations which match the specified identifer regex
## only look between begin and end
function(cmake_token_range_find_invocations range identifier )
  set(args ${ARGN})
  list_extract(range begin end)

  set(limit ${args})
  set(current ${begin})
  set(result)
  set(count 0)
  while(current)
    if(limit AND NOT "${count}" LESS "${limit}")
      break()
    endif()
    if("${current}_" STREQUAL "${end}_")
      break()
    endif()

    map_tryget(${current} type)
    ans(type)
    if("${type}" STREQUAL "command_invocation")
      map_tryget(${current} value)
      ans(current_identifier)
      if("${current_identifier}" MATCHES "^${identifier}$")
        list(APPEND result ${current})
        math(EXPR count "${count} + 1")
      endif()
    endif()

    map_tryget(${current} next)
    ans(current)
  endwhile()
  return_ref(result)  
endfunction()




## `(<start:<token>> <token type> [<value:<regex>>])-><token>`  
##
## returns the next token that has the specified token type
## or null
function(cmake_token_range_find_next_by_type range type)
  list_extract(range current end)
  set(regex ${ARGN})
  while(current AND NOT "${current}" STREQUAL "${end}")
    map_tryget(${current} type)
    ans(current_type)
    if("${current_type}" MATCHES "${type}")
      if(regex)
        map_tryget(${current} literal_value)
        ans(current_value)
        if("${current_value}" MATCHES "${regex}")
     #   print_vars(current_value regex match)
          return_ref(current)
        endif()
     #   print_vars(current_value regex nomatch)
      else()
        return_ref(current)
      endif()
    endif()
    map_tryget(${current} next)
    ans(current)
  endwhile()
endfunction()






## `(<cmake code>|<cmake token>...)-><cmake token>...`
##
## coerces the input to a token list
function(cmake_tokens tokens)
  string_codes()

  if("${tokens}" MATCHES "^${ref_token}:")
    return_ref(tokens)
  endif()
  cmake_tokens_parse("${tokens}" --extended)
  return_ans()
endfunction()




## `(<cmake code> [--extended])-><cmake token>...`
##
## this function parses cmake code and returns a list linked list of tokens 
##
## ```
## <token> ::= { 
##  type: "command_invocation"|"bracket_comment"|"line_comment"|"quoted_argument"|"unquoted_argument"|"nesting"|"nesting_end"|"file"
##  value: <string> the actual string as is in the source code 
##  [literal_value : <string>] # the value which actually is meant (e.g. "asd" -> asd  | # I am A comment -> ' I am A comment')
##  next: <token>
##  previous: <token>
## }
## <nesting token> ::= <token> v {
##   "begin"|"end": <nesting token>
## }
## <extended token> ::= (<token>|<nesting token>) v {
##  line:<uint> # the line in which the token is found
##  column: <uint> # the column in which the token starts
##  length: <uint> # the length of the token 
## }
## ```
function(cmake_tokens_parse code)
  set(args ${ARGN})
  list_extract_flag(args --extended)
  ans(extended)

  regex_cmake()

  set(line_counter 0)
  set(column_counter 0)
  set(nestings)
  set(previous)
  set(tokens)

  ## encode list to remove unwanted codes
  string_encode_list("${code}") # string replace \r ""?
  ans(code)
  string(REGEX MATCHALL "${regex_cmake_token}" literal_values "${code}")
  
  while(true)
    list(LENGTH literal_values literals_left)
    if(NOT literals_left)
      break()
    endif()

    list(GET literal_values 0 literal)
    list(REMOVE_AT literal_values 0)

    map_new()
    ans(token)
    list(APPEND tokens ${token})

    set(literal_value "${literal}")
    if("${literal}_" STREQUAL "(_")
      set(type nesting)
      list(INSERT nestings 0 ${token})

    elseif("${literal}_" STREQUAL ")_")
      set(type nesting_end)
      if(NOT nestings)
        error("unbalanced nesting expressions")
        return()
      endif()
      list(GET nestings 0 begin)
      list(REMOVE_AT nestings 0)
      map_set(${begin} end ${token})
      map_set(${token} begin ${begin})

    elseif("${literal}" MATCHES "^${regex_cmake_space}$")
      set(type white_space)
    elseif("${literal}" STREQUAL "${regex_cmake_newline}")
      set(type new_line)
    else()
      ## all literals here need the decoded literal value
      string_decode_list("${literal}")
      ans(literal)
      if("${literal}" MATCHES "^${regex_cmake_bracket_comment}$")
        set(type bracket_comment)
        set(literal_value "${CMAKE_MATCH_1}")
      elseif("${literal}" MATCHES "^${regex_cmake_line_comment}$")
        set(type line_comment)
        set(literal_value "${CMAKE_MATCH_1}")
      elseif("${literal}" MATCHES "^${regex_unquoted_argument}$")
        set(type unquoted_argument)
        cmake_string_unescape("${CMAKE_MATCH_0}")
        ans(literal_value)
        set(literal_value "${literal_value}")
      
        if(NOT nestings AND "${literal}_" MATCHES "^${regex_cmake_identifier}_$")
          if("_${literal_values}" MATCHES "^_(${regex_cmake_space};)?${regex_cmake_nesting_start_char};")
            set(type command_invocation)
          endif()
        endif()
      elseif("${literal}" MATCHES "^\"(.*)\"$")
        set(type quoted_argument)
        cmake_string_unescape("${CMAKE_MATCH_1}")
        ans(literal_value)   
        set(literal_value "${literal_value}")
      else()
        message("unknown token ${literal}")
        error("unknown token ${literal}")
        return()
      endif()
    endif()

    map_set(${token} type "${type}")
    map_set(${token} value "${literal}")
    map_set(${token} literal_value "${literal_value}")
    
    if(extended) #these are computed values which make parsing slow
      if(nestings)
        list(GET nestings 0 current_nesting)
        map_append(${current_nesting} children ${token})
        map_set(${token} parent "${current_nesting}")
      endif()
      map_set_hidden(${token} previous ${previous})
      map_property_string_length("${token}" value)
      ans(length)
      map_set("${token}" length "${length}")
      map_set(${token} line ${line_counter})
      map_set(${token} column ${column_counter})
      math(EXPR  column_counter "${column_counter} + ${length}")
      if("${type}" STREQUAL "new_line")
        set(column_counter 0)
        math(EXPR line_counter "${line_counter} + 1")
      endif()
    endif()

    ## setup the linked list
    if(previous)
      map_set_hidden(${previous} next ${token})
    endif()
    set(previous ${token})
    list(APPEND tokens ${token})
  endwhile()
  cmake_token_eof()
  ans(eof)
  if(previous)
    map_set(${previous} next ${eof})
    map_set(${eof} previous ${previous})
  endif()

  list(APPEND tokens ${eof})
    
  return_ref(tokens)
endfunction() 






## `(<cmake token range>|<cmake token>...|<cmake code>)-><cmake token range>`
##
## coerces the input to become a token range 
## if the input already is a token range it is returned
## if the input is a list of tokens the token range will be extracted
## if the input is a string it is assumed to be cmake code and parsed to return a token range
function(cmake_token_range )    
  cmake_tokens("${ARGN}")
  ans(range)
  list_pop_front(range)
  ans(begin)
  list_pop_back(range)
  ans(end)
  return(${begin} ${end})
endfunction()





## `(<start:<cmake token>> <end:<cmake token>>?)-><cmake code>`
## 
## generates the cmake code corresponding to the cmake token range
function(cmake_token_range_serialize range)
  cmake_token_range_to_list("${range}")
  ans(tokens)
  set(result)
  foreach(token ${tokens})
    map_tryget(${token} value)
    ans(value)
    set(result "${result}${value}")
  endforeach()

  return_ref(result)
endfunction()





## `(<start:<cmake token>> [<end: <cmake token>])-><cmake token>...`
##
## returns all tokens for the specified range (or the end of the tokens)
function(cmake_token_range_to_list range)
  list_extract(range begin end)
  set(current ${begin})
  set(tokens)
  while(true)
    if(NOT current OR "${current}" STREQUAL "${end}")
      break()
    endif() 
    list(APPEND tokens ${current})
    map_tryget(${current} next)
    ans(current)
  endwhile()
  return_ref(tokens)
endfunction()





function(cmake_token_range_targets_filter range target_name)
  cmake_token_range("${range}")
  ans(range)
  cmake_invocation_filter_token_range("${range}" 
    invocation_identifier MATCHES "^(add_custom_target)|(add_test)|(add_library)|(add_executable)|(target_link_libraries)|(target_include_directories)|(target_compile_options)|(target_compile_definitions)$" 
    AND invocation_arguments MATCHES "^${target_name}(;|$)"
    )
  ans(target_invocations)
  map_new()
  ans(targets)

  set(target_definition_invocation)
  set(target_include_directories_invocation)
  set(target_link_libraries_invocation)
  set(target_compile_definitions_invocation)
  set(target_compile_options_invocation)
  foreach(target_invocation ${target_invocations})
    map_tryget(${target_invocation} invocation_arguments)
    ans_extract(target_name)
    ans(values)
    map_tryget(${targets} ${target_name})
    ans(target)
    if(NOT target)
      map_new()
      ans(target)
      map_new()
      ans(target_invocations)
      map_set_hidden(${target} target_invocations ${target_invocations})
      map_set(${targets} ${target_name} ${target})
      map_set(${target} target_name ${target_name})
    else()
      map_tryget(${target} target_invocations)
      ans(target_invocations)
    endif()

    map_tryget(${target_invocation} invocation_identifier)
    ans(invocation_identifier)

    if("${invocation_identifier}" MATCHES "^add_(.+)$")
      set(type target_source_files)
      map_set(${target} target_type ${CMAKE_MATCH_1})
    elseif("${invocation_identifier}" STREQUAL "target_link_libraries")
      set(type target_link_libraries)      
    elseif("${invocation_identifier}" STREQUAL "target_include_directories")
      set(type target_include_directories)      
    elseif("${invocation_identifier}" STREQUAL "target_compile_options")
      set(type target_compile_options)      
    elseif("${invocation_identifier}" STREQUAL "target_compile_definitions")
      set(type target_compile_definitions)      
    endif()
    map_set(${target} ${type} ${values})
    map_set(${target_invocations} "${type}" ${target_invocation} )
  endforeach()
  return_ref(targets)
endfunction()




## `(<&<token>>)-><token>`
##
## advances the current token to the next token
macro(cmake_token_advance token_ref)
  map_tryget(${${token_ref}} next)
  ans(${token_ref})
endmacro()





## `(<&cmake token>)-><cmake token>`
## 
## the token ref contains the previous token after invocation
macro(cmake_token_go_back token_ref)
  map_tryget(${${token_ref}} previous)
  ans(${token_ref})
endmacro()






## `(<cmake token range> <predicate> [--reverse] [--skip <uint>] [--take <uint>])-><cmake token>...`
##
## filters the specified token range for tokens matching the predicate (access to value and type)
## e.g. `cmake_token_range_filter("set(a b c d)" type MATCHES "^argument$" AND value MATCHES "[abd]" --reverse --skip 1 --take 1 )` 
## <% 
##   cmake_token_range_filter("set(a b c d)" type MATCHES "^argument$" AND value MATCHES "[abd]" --reverse --skip 1 --take 1 ) 
##   ans(res)
##   #template_out_json(${res})
## %>
## 
function(cmake_token_range_filter range )
  arguments_encoded_list2(1 ${ARGC})
  ans(args)
  
  list_extract_flag(args --reverse)
  ans(reverse)
  
  cmake_token_range("${range}")
  if(reverse)
    ans_extract(end current)
  else()
    ans_extract(current end)
  endif()

  list_extract_labelled_value(args --skip)
  ans(skip)
  list_extract_labelled_value(args --take)
  ans(take)
  if("${take}_" STREQUAL "_")
    set(take -1)
  endif()
  set(predicate ${args})
  set(result)
  while(take AND current AND NOT "${current}" STREQUAL "${end}")
    map_tryget("${current}" literal_value)
    ans(value)
    map_tryget("${current}" type)
    ans(type)

    eval_predicate(${predicate})
    ans(predicate_holds)

    #print_vars(reverse predicate predicate_holds value type)
    #string(REPLACE "{type}" "${type}" current _predicate "${args}")
    #string(REPLACE "{value}" "${value}" current_predicate "${current_predicate}")
    if(predicate_holds)

      if(skip)
        math(EXPR skip "${skip} - 1")
      else()
        list(APPEND result ${current})
        if(${take} GREATER 0)
          math(EXPR take "${take} - 1")
        endif()
      endif()
    endif()
    if(reverse)
      cmake_token_go_back(current)
    else()
      cmake_token_advance(current)
    endif()
  endwhile()
  return_ref(result)
endfunction() 







## `(...)->...` 
##
## convenience function
## same as cmake_token_range_filter however returns the token values
function(cmake_token_range_filter_values range)
  set(args ${ARGN})
  list_extract_flag(args --encode)
  ans(encode)## todo
  cmake_token_range_filter("${range}" ${args})
  ans(tokens)
  list_select_property(tokens literal_value)
  return_ans()
endfunction()





## `(<where:<cmake token>> <cmake token range> )-><token range>`
##
## inserts the specified token range before <where>
function(cmake_token_range_insert where what)
  cmake_token_range("${what}")
  ans_extract(begin end)
  map_tryget("${where}" previous)
  ans(previous)

  if(previous)
    map_set_hidden(${previous} next ${begin})
    map_set_hidden(${begin} previous ${previous})  
  endif()
  map_set_hidden(${end} next ${where})
  map_set_hidden(${where} previous ${end}) 

  return(${begin} ${end})
endfunction()




## `(<cmake token range>)-><void>`
##
## removes the specified token range from the linked list
function(cmake_token_range_remove range)
  list_extract(range begin end)
  map_tryget("${begin}" previous)
  ans(before)
  map_tryget("${end}" next)
  ans(after)
  map_set("${before}" next ${after})
  map_set("${after}" previous ${before})
  return()
endfunction()






## `(<range:<cmake token range>> <replace_range:<cmake token range>>)-><cmake token range>`
## 
## replaces the specified range with the specified replace range
## returns the replace range
function(cmake_token_range_replace range replace_range)
  cmake_token_range("${range}")
  ans_extract(start end)
  cmake_token_range("${replace_range}")
  ans_extract(replace_start replace_end)
  map_tryget(${start} previous)
  ans(previous)
  map_set(${previous} next ${replace_start})
  map_set(${replace_start} previous ${previous})
  map_set(${end} previous ${replace_end})
  map_set(${replace_end} next ${end})
  return(${replace_start} ${replace_end})
endfunction()







  
function(cmake_token_eof)
  map_new()
  ans(token)
  map_set(${token} type eof)
  map_set(${token} value "")
  map_set(${token} literal_value "")
  return_ref(token)
endfunction()




## `(<cmake token range> <section_name:<string>>)-><cmake token range>`
##
## finds the correct comment section or returns nothing 
function(cmake_token_range_comment_section_find range regex_section_name)

  set(regex_section_begin_specific "^[# ]*<section[ ]+name[ ]*=[ ]*\"${regex_section_name}\"[ ]*>[ #]*$")
  set(regex_section_begin_any "^[# ]*<section.*>[ #]*$")
  set(regex_section_end "^[# ]*<\\/[ ]*section[ ]*>[# ]*$")



  list_extract(range current end)


  cmake_token_range_find_next_by_type("${current};${end}" "^line_comment$" "${regex_section_begin_specific}")
  ans(current)

  if(NOT current)
    error("section ${section_name} not found")
    return()
  endif()

  set(section_begin_token ${current})

  cmake_token_advance(current)


  set(section_depth 1)
  set(section_end_token)

  while(current)

    cmake_token_range_find_next_by_type("${current};${end}" "^line_comment$" "(${regex_section_begin_any})|(${regex_section_end})")
    ans(current)

    map_tryget(${current} literal_value)
    ans(literal_value)

    if("${literal_value}" MATCHES "${regex_section_begin_any}")
      math(EXPR section_depth "${section_depth} + 1")
    else()
      math(EXPR section_depth "${section_depth} - 1")
    endif()

    if(NOT section_depth)
      set(section_end_token ${current})
      break()
    endif()

    map_tryget(${current} next)
    ans(current)

  endwhile()

  if(NOT section_end_token)
    error("unbalanced section close")
    return()
  endif()
  
  ## advance twice: comment->newline->begin of section
  cmake_token_advance(section_begin_token)
  cmake_token_advance(section_begin_token)

  return(${section_begin_token} ${section_end_token})
endfunction()





  function(cmake_token_range_comment_section_find_all range regex_section_name)
    cmake_token_range("${range}")
    ans_extract(current end)

    set(sections)
    while(current)
      cmake_token_range_comment_section_find("${current};${end}" "${regex_section_name}")
      ans(section)
      ans_extract(section_begin section_end)

      if(NOT section)
        break()
      endif()
      list(APPEND sections ${section}) 

      map_tryget(${section_end} next)
      ans(current)
    endwhile()  

    return_ref(sections)

  endfunction()






## navigates to the specified target sectopn returning its range
## sections are navigated by a simple navigation expression e.g. a.b.c
function(cmake_token_range_comment_section_navigate range path)
  cmake_token_range("${range}")
  ans(range)
  string(REGEX MATCHALL "[^\\.]+" section_identifiers "${path}" )
  foreach(section_identifier ${section_identifiers})
    cmake_token_range_comment_section_find("${range}" "${section_identifier}")
    ans(section)
    if(NOT section)
      error("could not find section '${section_identifier}'")
      return()
    endif() 
    set(range ${section})
  endforeach()

  return_ref(range)
endfunction()




## `(<cmake token range> <predicate> [--skip <uint>] [--take <uint>] [--reverse])-><cmake invocation>...`
##
## searches for invocations matching the predicate allowing to skip and take a certain amount of matches
## also allows reverse serach when specifying the corresponding flag.
##
## the predicate is the same as what one would write into an if clause allows access to the following variables:
## * invocation_identifier
## * invocation_arguments
## e.g. `invocation_identifier MATCHES "^add_.*$"` would return only invocations starting with add_
## also see `eval_predicate`
## ```
## <cmake invocation> ::= {
##    invocation_identifier: <string>      # the name of the invocation
##    invocation_arguments: <string>...    # the arguments of the invocation
##    invocation_token: <cmake token>      # the token representing the invocation
##    arguments_begin_token: <cmake token> # the begin of the arguments of the invocation (after the opening parenthesis)
##    arguments_end_token: <cmake token>   # the end of the arguments of the invocation (the closing parenthesis)
## }
## ```
##
function(cmake_invocation_filter_token_range range)
  arguments_encoded_list2(1 ${ARGC})
  ans(args)

  list_extract_flag_name(args --reverse)
  ans(reverse)

  cmake_token_range("${range}")
  ans(range)
  list_extract(range begin end)
  set(current ${begin})
  list_extract_labelled_keyvalue(args --skip)
  ans(skip)
  list_extract_labelled_keyvalue(args --take)
  ans(take)
  if("${take}_" STREQUAL "_")
    set(take -1)
  endif()


  set(result)
  while(take AND current)
    cmake_token_range_filter("${current};${end}" {type} STREQUAL "command_invocation" --take 1 ${reverse})
    ans(invocation_token)
    if(NOT invocation_token)
      break()
    endif()
    if(reverse)
      set(end)
    endif()
    cmake_token_range_filter("${invocation_token};${end}" {type} STREQUAL "nesting" --take 1)
    ans(arguments_begin_token)

    map_tryget(${arguments_begin_token} end)
    ans(arguments_end_token)
    map_tryget(${arguments_end_token} next)
    ans(arguments_after_end_token)

    cmake_token_range_filter_values("${invocation_token};${arguments_after_end_token}" {type} MATCHES "(command_invocation)|(nesting)|(argument)")
    ans(invocation)

    ## get invocation_identifier and invocation_arguments
    set(invocation_arguments ${invocation})
    list_pop_front(invocation_arguments)
    ans(invocation_identifier)
    list_pop_front(invocation_arguments)
    list_pop_back(invocation_arguments)
    

    eval_predicate(${args})
    ans(predicate_holds)
    #print_vars(invocation_token.type invocation_token.value predicate_holds args)

    ## check if invocation matches the custom predicate
    ## skip and take the specific invocations
    if(predicate_holds)
      if(skip)
        math(EXPR skip "${skip} - 1")
      else()
        cmake_token_advance(arguments_begin_token)
        map_capture_new(
          invocation_identifier 
          invocation_arguments 
          invocation_token 
          arguments_begin_token 
          arguments_end_token
        )
        ans_append(result)
        if(${take} GREATER 0)
          math(EXPR take "${take} - 1")
        endif()
      endif() 
    endif() 

    if(reverse)
      map_tryget(${invocation_token} previous )
      ans(end)
    else()
      set(current ${arguments_after_end_token})
    endif()
  endwhile()
  return_ref(result)
endfunction()





## `(<invocation:<command invocation>>)->[<start:<token>> <end:<token>>]`
## 
## returns the token range of the invocations arguments given an invocation token
function(cmake_invocation_get_arguments_range invocation)
  cmake_token_range_find_next_by_type("${invocation}" nesting)
  ans(arguments_begin)
  map_tryget(${arguments_begin} end)
  ans(arguments_end)
  map_tryget(${arguments_begin} next)
  ans(arguments_begin)
  return(${arguments_begin} ${arguments_end})
endfunction()





## `(<cmake invocation>)-><void>`
##
## removes the specified invocation from its context by removing the invocation token and the arguments from the linked list that they are part
function(cmake_invocation_remove invocation)
  map_tryget(${invocation} invocation_token)
  ans(begin)
  map_tryget(${invocation} arguments_end_token)
  ans(end)
  cmake_token_range_remove("${begin};${end}")
  return()
endfunction()






## `(<command invocation token> <values: <any...>>)-><void>`
##
## replaces the arguments for the specified invocation by the
## specified values. The values are quoted if necessary
function(cmake_invocation_token_set_arguments invocation_token)
  cmake_invocation_get_arguments_range("${invocation_token}")
  ans_extract(begin end)

  cmake_arguments_quote_if_necessary(${ARGN})
  ans(arguments)

  list(LENGTH ARGN count)
  string(LENGTH "${ARGN}" len)
  

  if(${len} LESS 70 OR ${count} LESS 2)
    string_combine(" " ${arguments})
    ans(argument_string)
  else()
    map_tryget(${invocation_token} column)
    ans(column)
    string_repeat(" " "${column}")
    ans(last_indentation)
    math(EXPR column "${column} + 2")
    string_repeat(" " "${column}")
    ans(indentation)
    string_combine("\n${indentation}" ${arguments})
    ans(argument_string)
    set(argument_string "${argument_string}\n${last_indentation}")
  endif()

  cmake_token_range("${argument_string}")
  ans(argument_token_range)


  cmake_token_range_replace("${begin};${end}" "${argument_token_range}")
  return()
endfunction()




function(cmake_token_range_variable range var_name)
  set(args ${ARGN})

  cmake_invocation_filter_token_range("${range}" 
    invocation_identifier STREQUAL "set" 
    AND invocation_arguments MATCHES "^${var_name}"  
    --take 1 
    )
  ans(invocation)

  
  if(NOT invocation)
    messagE(FATAL_ERROR "could not find 'set(${var_name} ...)'")
  endif()

  map_tryget(${invocation} invocation_token)
  ans(invocation_token)
  map_tryget(${invocation} invocation_arguments)
  ans(arguments)
  list_pop_front(arguments) ## remove var_name
  list_modify(arguments ${args})
  cmake_invocation_token_set_arguments(${invocation_token} ${var_name} ${arguments})
  return_ref(arguments)
endfunction()





## navigates to and tries to change variable
function(cmake_token_range_variable_navigate range variable_path)
  cmake_token_range("${range}")
  ans(range)
  set(args ${ARGN}) 

  string(REGEX MATCH "[^\\.]+$" variable_name "${variable_path}")
  string(REGEX REPLACE "\\.?[^\\.]+$" "" section_path "${variable_path}" )
  cmake_token_range_comment_section_navigate("${range}" "${section_path}")
  ans(section)

  if(NOT section)
    return()  
  endif()
  cmake_token_range_variable("${section}" "${variable_name}" ${args})
  return_ans()  
endfunction()




macro(add_custom_target)
  _add_custom_target(${ARGN})


  event_emit(add_custom_target ${ARGN})
  event_emit(on_target_added custom ${ARGN})
  target_register(${ARGN})
endmacro()





macro(add_dependencies)
  _add_dependencies(${ARGN})
  event_emit(add_dependencies ${ARGN})

endmacro()





macro(add_executable)
  _add_executable(${ARGN})
  event_emit(add_executable ${ARGN})
  event_emit(on_target_added executable ${ARGN})
  target_register(${ARGN})
endmacro()




# overwrites add_library
# same function as cmakes original add_library
# emits the event add_library with all parameters of the add_library call
# emits the event on_target_added library with all parameters of the call added
# registers the target globally so it can be iterated via 
macro(add_library)
  _add_library(${ARGN})
  event_emit(add_library ${ARGN})

  event_emit(on_target_added library ${ARGN})
  target_register(${ARGN})


  
endmacro()






macro(add_test)
  _add_test(${ARGN})
  event_emit(add_test ${ARGN})
  event_emit(on_target_added test ${ARGN})
  target_register(${ARGN})

endmacro()




# wrapper for find_package using cps
#find_package(<package> [version] [EXACT] [QUIET]
#             [[REQUIRED|COMPONENTS] [components...]]
#             [NO_POLICY_SCOPE])
macro(find_package)
  set_ans("")
  event_emit(on_find_package ${ARGN})
  if(__ans)
    ## an event returns a cmake package map 
    ## which contains the correct variables
    ## also it contains a hidden field called find_package_return_value
    ## which is the return value for find_package

    scope_import_map("${__ans}")
    map_tryget("${__ans}" find_package_return_value)
  else()  
    _find_package(${ARGN})
    set_ans("")
  endif()
endmacro()




macro(include_directories)
  _include_directories(${ARGN})
  event_emit(include_directories "${ARGN}")
endmacro()




# overwrites install command
#  emits event install and on_target_added(install ${ARGN)
# registers install target globally
macro(install)
  _install(${ARGN})
  event_emit(install ${ARGN})

  event_emit(on_target_added install install ${ARGN})
  target_register(install install ${ARGN})

endmacro()







# overwrites project so that it can be registered
macro(project)
  set(parent_project_name "${PROJECT_NAME}")
  _project(${ARGN})
  set(project_name "${PROJECT_NAME}") 
  project_register(${ARGN})
  event_emit("project" ${ARGN})
endmacro()







macro(target_compile_definitions)
  _target_compile_definitions(${ARGN})
  event_emit(target_compile_definitions ${ARGN})

endmacro()





macro(target_compile_options)
  _target_compile_options(${ARGN})
  event_emit(target_compile_options ${ARGN})

endmacro()




function(target_include_directories target)

if(NOT COMMAND _target_include_directories)
  cmake_parse_arguments("" "SYSTEM;BEFORE;PUBLIC;INTERFACE;PRIVATE" "" "" ${ARGN} )
  message(DEBUG "using fallback version of target_include_directories, consider upgrading to cmake >= 2.8.10")
  
  if(_SYSTEM OR _BEFORE OR _INTERFACE OR _PRIVATE)
    message(FATAL_ERROR "shim for target_include_directories does not support SYSTEM, PRIVATE, INTERFACE or BEFORE upgrade to cmake >= 2.8.10")
  endif()
    foreach(arg ${ARGN})
      if(TARGET "${arg}")
        get_property(includes TARGET ${arg} PROPERTY INCLUDE_DIRECTORIES)
        set_property(TARGET ${target} APPEND PROPERTY ${includes})
      else()
        message(FATAL_ERROR "shim version of target_include_directories only supports targets. upgrade cmake to >=2.8.10")
      endif()
    endforeach()
  return()
else()
  # default implementation
  _target_include_directories(${target} ${ARGN})
endif()
  event_emit(target_include_directories ${ARGN})
  
endfunction()




# overwrites target_link_libraries
# emits the event target_link_libraries
macro(target_link_libraries)
  _target_link_libraries(${ARGN})
  target_link_libraries_register(${ARGN})
  event_emit(target_link_libraries ${ARGN})
  
endmacro()

function(target_link_libraries_register target)
  
endfunction()




# prints the list of known targets 
function(print_targets)
  target_list()
  ans(res)
  foreach(target ${res})
    message("${target}")
  endforeach()

endfunction()


function(print_project_tree)
  map_tryget(global project_map)
  ans(pmap)

  json_print(${pmap})
  return()

endfunction()


function(print_target target_name)
  target_get_properties(${target_name})
  ans(res)
  json_print(${res})
endfunction()




# 
function(project_register name)
  map_new()
  ans(pmap)
  map_set(global project_map ${pmap})
  function(project_register name)
    map_new()
    ans(cmake_current_project)
    map_set(${cmake_current_project} name "${name}")
    map_set(${cmake_current_project} directory "${CMAKE_CURRENT_LIST_DIR}")
    map_append(global projects ${cmake_current_project})
    map_append(global project_names ${name})
    map_tryget(global project_map)
    ans(pmap)
    map_set(${pmap} ${name} ${cmake_current_project})
  endfunction()
  project_register(${name} ${ARGN})
  return_ans()
endfunction()

# returns the project object identified by name
function(project_object)
  set(name ${ARGN})
  if(NOT name)
    # set to current project name
    set(name ${project_name})
    if(NOT name)
      set(name "${PROJECT_NAME}")
    endif()
  endif()
  
  map_tryget(global project_map)
  ans(res)
  if(NOT res)
    return()
  endif()
  map_tryget(${res} ${name})
  return_ans()
endfunction()

# returns the names of all project
macro(project_list)
  map_tryget(global project_names)
endmacro()





function(target_append tgt_name key)
	set_property(
		TARGET "${tgt_name}"
		APPEND
		PROPERTY "${key}"
		${ARGN})
	return()
endfunction()






function(target_append_string tgt_name key)
	set_property(
		TARGET "${tgt_name}"
		APPEND_STRING
		PROPERTY "${key}"
		${ARGN})
	return()
endfunction()







function(target_get tgt_name key)
	get_property(
		val
		TARGET "${tgt_name}"
		PROPERTY "${key}"
		)
	return_ref(val)
endfunction()






function(target_has tgt_name key)
	get_property(
		val
		TARGET "${tgt_name}"
		PROPERTY "${key}"
		SET)
	return_ref(val)
endfunction()






# returns all known target names
macro(target_list)
  map_tryget(global target_names)
endmacro()





# registers the target globally
# the name of the target is added to targets
#  or target_list()
function(target_register target_name)
  map_new()
  ans(target_map)
  map_set(global target_map ${target_map})
  function(target_register target_name)
    map_new()
    ans(tgt)
    map_set(${tgt} name "${target_name}")
    map_set(${tgt} project_name ${project_name})
    map_append(global targets ${tgt})
    map_append(global target_names ${target_name}) 
    map_get(global target_map)
    ans(target_map)
    map_set(${target_map} ${target_name} ${tgt}) 
    project_object()
    ans(proj)
    if(proj)
      map_append(${proj} targets ${tgt})
    endif()
    return_ref(tgt)
  endfunction()
  target_register(${target_name} ${ARGN})
  return_ans()
endfunction()









function(target_set tgt_name key)
	set_property(
		TARGET "${tgt_name}"
		PROPERTY "${key}"
		${ARGN}
		)
	return()
endfunction()




## 
## executes the cmakepp command line as a separate process
##
## 
function(cmakepp)
  cmakepp_config(base_dir)
  ans(base_dir)
  cmake("-P" "${base_dir}/cmakepp.cmake" ${ARGN})
  return_ans()    
endfunction()







function(cmakepp_cli)
  set(args ${ARGN})

  if(NOT args)
    ## get command line args and remove executable -P and script file
    commandline_args_get(--no-script)
    ans(args)
  endif()


  list_extract_flag(args --timer)
  ans(timer)
  list_extract_flag(args --silent)
  ans(silent)
  list_extract_labelled_value(args --select)
  ans(select)

  ## get format
  list_extract_flag(args --json)
  ans(json)
  list_extract_flag(args --qm)
  ans(qm)
  list_extract_flag(args --table)
  ans(table)
  list_extract_flag(args --csv)
  ans(csv)
  list_extract_flag(args --xml)
  ans(xml)
  list_extract_flag(args --plain)
  ans(plain)
  list_extract_flag(args --ini)
  ans(ini)

  set(lazy_cmake_code)
  foreach(arg ${args})
    cmake_string_escape("${arg}")
    set(lazy_cmake_code "${lazy_cmake_code} ${__ans}")
  endforeach()

  #string_combine(" " ${args})
  #ans(lazy_cmake_code)

  lazy_cmake("${lazy_cmake_code}")
  ans(cmake_code)

  ## execute code
  set_ans("")
  if(timer)
    timer_start(timer)
  endif()
  eval("${cmake_code}")
  ans(result)

  if(timer)
    timer_print_elapsed(timer)
  endif()

  if(select)
    string(REGEX REPLACE "@([^ ]*)" "{result.\\1}" select "${select}")
    format("${select}")
    ans(result)
   # assign(result = "result${select}")
  endif()


  ## serialize code
   if(json)
    json_indented("${result}")
    ans(result)
  elseif(ini)
    ini_serialize("${result}")
    ans(result)
   elseif(qm)
    qm_serialize("${result}")
    ans(result)
   elseif(table)
      table_serialize("${result}")
      ans(result)
    elseif(csv)
      csv_serialize("${result}")
      ans(result)
    elseif(xml)
      xml_serialize("${result}")
      ans(result)
    elseif(plain)

    else()
      json_indented("${result}")
      ans(result)
   endif()



  ## print code
  if(NOT silent)
    echo("${result}")
  endif()
  return_ref(result)
endfunction()








## cmakepp_compile() 
##
## compiles cmakepp into a single file which is faster to include
function(cmakepp_compile target_file)
  path_qualify(target_file)
  cmakepp_config(base_dir)
  ans(base_dir)

  file(STRINGS "${base_dir}/cmakepp.cmake" cmakepp_main_file)

  foreach(line ${cmakepp_main_file})
    if("_${line}" STREQUAL "_include(\"\${cmakepp_base_dir}/cmake/core/require.cmake\")")

    elseif("_${line}" STREQUAL "_require(\"\${cmakepp_base_dir}/cmake/*.cmake\")")

      file(GLOB_RECURSE files "${base_dir}/cmake/**.cmake")

      foreach(file ${files} ) 
        file(READ  "${file}" content)      
        file(APPEND "${target_file}" "\n\n\n${content}\n\n")
      endforeach()
    elseif("_${line}" STREQUAL "_include(\"\${cmakepp_base_dir}/cmake/task/task_enqueue\")")
      file(READ "${base_dir}/cmake/task/task_enqueue" content)
      file(APPEND "${target_file}" "\n\n\n${content}\n\n")

    else()
      file(APPEND "${target_file}" "${line}\n")
  endif()
  endforeach()
endfunction()






## 
## goes through all of cmakepp's README.md.in files and generates them
function(cmakepp_compile_docs)
  cmakepp_config(base_dir)
  ans(base_dir)
  file(GLOB_RECURSE template_paths "${base_dir}/**README.md.in")
  
  foreach(template_path ${template_paths})
      get_filename_component(template_dir "${template_path}" PATH)
      set(output_file "${template_dir}/README.md")
      message("generating ${output_file}")
      template_run_file("${template_path}")
      ans(generated_content)
      fwrite("${output_file}" "${generated_content}")
  endforeach()

endfunction()




## 
##
## invokes the cmakepp project command line interface
function(cmakepp_project_cli)
  #commandline_args_get(--no-script)
  #ans(args)
  set(args ${ARGN})

  list_extract_any_flag(args -g --global)
  ans(global)


  list_extract_any_flag(args -v --verbose)
  ans(verbose)


  if(verbose)

    event_addhandler("on_log_message" "[](entry)print_vars(entry)")
    event_addhandler("project_on_opening" "[](proj) message(FORMAT '{event.event_id}: {proj.content_dir}'); message(PUSH)")
    event_addhandler("project_on_opened" "[](proj) message(FORMAT '{event.event_id}')")
    event_addhandler("project_on_loading" "[](proj) message(FORMAT '{event.event_id}'); message(PUSH)")
    event_addhandler("project_on_package_loading" "[](proj pack) message(FORMAT '{event.event_id}: {pack.uri}'); message(PUSH)")
    event_addhandler("project_on_package_loaded" "[](proj pack)  message(POP); message(FORMAT '{event.event_id}: {pack.uri}')")
    event_addhandler("project_on_package_reload" "[](proj pack)   message(FORMAT '{event.event_id}: {pack.uri}')")
    event_addhandler("project_on_package_cycle" "[](proj pack)   message(FORMAT '{event.event_id}: {pack.uri}')")
    event_addhandler("project_on_package_unloading" "[](proj pack) message(FORMAT '{event.event_id}: {pack.uri}'); message(PUSH)")
    event_addhandler("project_on_package_unloaded" "[](proj pack)  message(POP); message(FORMAT '{event.event_id}: {pack.uri}')")
    event_addhandler("project_on_package_materializing" "[](proj pack) message(FORMAT '{event.event_id}: {pack.uri}'); message(PUSH)")
    event_addhandler("project_on_package_materialized" "[](proj pack)  message(POP); message(FORMAT '{event.event_id}: {pack.uri} => {pack.content_dir}')")
    event_addhandler("project_on_package_dematerializing" "[](proj pack) message(FORMAT '{event.event_id}: {pack.uri}'); message(PUSH)")
    event_addhandler("project_on_package_dematerialized" "[](proj pack)  message(POP); message(FORMAT '{event.event_id}: {pack.uri}')")
    event_addhandler("project_on_loaded" "[](proj) message(POP); message(FORMAT '{event.event_id}') ")
    event_addhandler("project_on_closing" "[](proj) message(FORMAT '{event.event_id}'); message(POP)")
    event_addhandler("project_on_closed" "[](proj) message(FORMAT '{event.event_id}: {proj.content_dir}')")
    event_addhandler("project_on_dependency_configuration_changed" "[](proj) message(FORMAT '{event.event_id}: {{ARGN}}')")
    event_addhandler("project_on_dependencies_materializing" "[](proj ) message(FORMAT '{event.event_id}'); message(PUSH)")
    event_addhandler("project_on_dependencies_materialized" "[](proj )  message(POP); message(FORMAT '{event.event_id}')")
    event_addhandler("project_on_package_ready" "[](proj pack)   message(FORMAT '{event.event_id}: {pack.uri}')")
    event_addhandler("project_on_package_unready" "[](proj pack)   message(FORMAT '{event.event_id}: {pack.uri}')")
  endif()


  list_extract_flag(args --save)
  ans(save)


  list_extract_labelled_value(args --project)
  ans(project_dir)

  if(global)
    dir_ensure_exists("~/.cmakepp")
    project_read("~/.cmakepp")
    ans(project)
    assign(project.project_descriptor.is_global = 'true')
  else()
    project_read("${project_dir}")
    ans(project)
  endif()

  list_pop_front(args)
  ans(cmd)

  if(NOT cmd)
    set(cmd run)
  endif()
  
  if("${cmd}" STREQUAL "init")
    list_pop_front(args)
    ans(path)
    project_open("${path}")
    ans(project)
  endif()

  if(NOT project)
    error("no project available")
    return()
  endif()

  map_tryget(${project} project_descriptor)
  ans(project_descriptor)
  map_tryget(${project_descriptor} package_source)
  ans(package_source)
  if(NOT package_source )
    message("no package source found")
    default_package_source()
    ans(package_source)
    map_set(${project_descriptor} package_source ${package_source})
  endif()


  if("${cmd}" STREQUAL "init")
  elseif("${cmd}" STREQUAL "get")

    if("${args}" MATCHES "(.+)\\((.*)\\)$")
      set(path "${CMAKE_MATCH_1}")
      set(call (${CMAKE_MATCH_2}))
    else()
      set(call)
      set(path ${args})
    endif()
    assign(res = "project.${path}" ${call})
  elseif("${cmd}" STREQUAL "set")
    list_pop_front(args)
    ans(path)
    set(call false)
    if("${path}_" STREQUAL "call_")
      list_pop_front(args)
      ans(path)
      set(call true)
    endif()


    if(NOT path)
      error("no path specified")
      return()
    endif()
    if(NOT call)
      assign("!project.${path}" = "'${args}'")
    else()
      list_pop_front(args)
      ans(func)
      assign("!project.${path}" = "${func}"(${args}))
    endif()
    set(save true)
    assign(res = "project.${path}")

  elseif("${cmd}" STREQUAL "run")
    package_handle_invoke_hook("${project}" cmakepp.hooks.run "${project}" "${project}" ${args})
    ans(res)
  else()
    call("project_${cmd}"("${project}" ${args}))
    ans(res)
  endif()

  project_write(${project})
  return_ref(res)

endfunction()




## sets up the cmakepp environment 
## creates aliases
##    icmake - interactive cmakepp
##    cmakepp - commandline interface to cmakepp 
##    pkg - package manager command line interface
function(cmakepp_setup_environment)
  cmakepp_config(base_dir)
  ans(base_dir)
  
  message(STATUS "creating alias `icmakepp`")  
  alias_create("icmakepp" "cmake -P ${base_dir}/cmakepp.cmake icmake")
  message(STATUS "creating alias `cmakepp`")  
  alias_create("cmakepp" "cmake -P ${base_dir}/cmakepp.cmake")
  message(STATUS "creating alias `pkg`")  
  alias_create("pkg" "cmake -P ${base_dir}/cmakepp.cmake cmakepp_project_cli")
  message(STATUS "creating alias `cml`")  
  alias_create("cml" "cmake -P ${base_dir}/cmakepp.cmake cmakelists_cli")
  message(STATUS "setting CMAKEPP_PATH to ${base_dir}/cmakepp.cmake ")

  shell_env_set(CMAKEPP_PATH "${base_dir}/cmakepp.cmake")



endfunction()




function(cmakepp_tool)
  set(args ${ARGN})
  list_pop_front(args)
  ans(path)

  pushd("${path}")
    cd("build" --create)
    cmake(
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=bin 
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG=bin 
      .. --process-handle)
    ans(handle)

    cmake(--build . --process-handle)
    ans(handle)

    json_print(${handle})

  popd()
  execute_process(COMMAND "${path}/build/bin/tool")
  return_ans()
endfunction()




  

## faster
function(encoded_list str)
  string_codes()
  eval("
    function(encoded_list str)
      if(\"\${str}_\" STREQUAL \"_\")
        return(${empty_code})
      endif()
    string(REPLACE \"[\" \"${bracket_open_code}\" str \"\${str}\")
    string(REPLACE \"]\" \"${bracket_close_code}\" str \"\${str}\")
    string(REPLACE \";\" \"${semicolon_code}\" str \"\${str}\")
    set(__ans \"\${str}\" PARENT_SCOPE)
  endfunction()
  ")
  encoded_list("${str}")
  return_ans()
endfunction()



## faster
function(encoded_list_decode str)
  string_codes()
  eval("
  function(encoded_list_decode str)
    if(\"\${str}_\" STREQUAL \"${empty_code}_\")
      return()
    endif()
    string(REPLACE \"${bracket_open_code}\" \"[\"  str \"\${str}\")
    string(REPLACE \"${bracket_close_code}\" \"]\"  str \"\${str}\")
    string(REPLACE \"${semicolon_code}\" \";\"  str \"\${str}\")
    set(__ans \"\${str}\" PARENT_SCOPE)
  endfunction()
  ")
  encoded_list_decode("${str}")
  return_ans()
endfunction()


  macro(encoded_list_get __lst idx)
    list(GET ${__lst} ${idx} __ans)
    string_decode_list("${__ans}")
  endmacro()

  function(encoded_list_set __lst idx)
    string_encode_list("${ARGN}")
    list_replace_at(${__lst} ${idx} ${__ans})
    set(${__lst} ${${__lst}} PARENT_SCOPE)
  endfunction()

  function(encoded_list_append __lst)
    string_encode_list("${ARGN}")
    list(APPEND "${__lst}" ${__ans})
    set(${__lst} ${${__lst}} PARENT_SCOPE)
  endfunction()



  function(encoded_list_remove_item __lst)
    string_encode_list("${ARGN}")
    if(NOT ${__lst})
      return()
    endif()
    list(REMOVE_ITEM ${__lst} ${__ans})
    set(${__lst} ${${__lst}} PARENT_SCOPE)
    return()
  endfunction()
  
  macro(encoded_list_remove_at __lst)
    list_remove_at(${__lst} ${ARGN})
  endmacro()

  function(encoded_list_pop_front __lst)
    list_pop_front(${__lst})
    ans(front)
    set(${__lst} ${${__lst}} PARENT_SCOPE)
    string_decode_list("${front}")
    return_ans()
  endfunction()

  function(encoded_list_peek_front __lst)
    list_peek_front(${__lst})
    ans(front)
    string_decode_list("${front}")
    return_ans()
  endfunction()

  function(encoded_list_pop_back __lst)
    list_pop_back(${__lst})
    ans(back)
    set(${__lst} ${${__lst}} PARENT_SCOPE)
    string_decode_list("${back}")
    return_ans()
  endfunction()

  function(encoded_list_peek_back __lst)
    list_peek_back(${__lst})
    ans(back)
    string_decode_list("${back}")
    return_ans()
  endfunction()





## returns a list of numbers [ start_index, end_index)
## if start_index equals end_index the list is empty
## if end_index is less than start_index then the indices are in declining order
## ie index_range(5 3) => 5 4
## (do not confuse this function with the `range_` functions)
function(index_range start_index end_index)
  
  if(${start_index} EQUAL ${end_index})
    return()
  endif()

  set(result)
  if(${end_index} LESS ${start_index})
    set(increment -1)
    math(EXPR end_index "${end_index} + 1")

  else()
    set(increment 1)
    math(EXPR end_index "${end_index} - 1")
  
  endif()
  
  foreach(i RANGE ${start_index} ${end_index} ${increment})
    list(APPEND result ${i})
  endforeach()
  return(${result})
endfunction()




## `(<list ref> <key:<string>>)-><any ....>`
##
## returns the elements after the specified key
function(list_after __lst __key)
  list(LENGTH ${__lst} __len)
  if(NOT __len)
    return()
  endif()
  list(FIND ${__lst} "${__key}" __idx)
  if(__idx LESS 0)
    return()
  endif()
  math(EXPR __idx "${__idx} + 1")
  list_split(__ __rhs ${__lst} ${__idx})
  return_ref(__rhs)
endfunction()





## `(<list&> <predicate:<[](<any>)->bool>>)-><bool>` 
##
## returns true iff predicate holds for all elements of `<list>` 
## 
function(list_all __list_all_lst __list_all_predicate)
  function_import("${__list_all_predicate}" as __list_all_predicate REDEFINE)
  foreach(it ${${__list_all_lst}})
    __list_all_predicate("${it}")
    ans(__list_all_match)
    if(NOT __list_all_match)
      return(false)
    endif()
  endforeach()
  return(true)
endfunction()




## `[](<list&> <predicate:<[](<any>)->bool>)-><bool>`
##
## returns true if there exists an element in `<list>` for which the `<predicate>` holds
function(list_any __list_any_lst __list_any_predicate)
  function_import("${__list_any_predicate}" as __list_any_predicate REDEFINE)

  foreach(__list_any_item ${${__list_any_lst}})
    __list_any_predicate("${__list_any_item}")
    ans(__list_any_predicate_holds)
    if(__list_any_predicate_holds)
      return(true)
    endif()
  endforeach()
  return(false)
endfunction()







## 
##
## returns all elements whose index are specfied
## 
function(list_at __list_at_lst)
  set(__list_at_result)
  foreach(__list_at_idx ${ARGN})
    list_get(${__list_at_lst} ${__list_at_idx})
    list(APPEND __list_at_result ${__ans})
  endforeach()
  return_ref(__list_at_result)
endfunction()




## `(<list&> <key:<string>>)-><any ....>`
##
## returns the elements before key
function(list_before __lst __key)
  list(LENGTH ${__lst} __len)
  if(NOT __len)
    return()
  endif()
  list(FIND ${__lst} "${__key}" __idx)
  if(__idx LESS 0)
    return()
  endif()
  math(EXPR __idx "${__idx} + 1")
  list_split(__lhs __ ${__lst} ${__idx})
  return_ref(__lhs)
endfunction()





## `(<list&> <query...>)-><bool>`
##  
## `<query> := <value>|'!'<value>|<value>'?'`
## 
## * checks to see that every value specified is contained in the list 
## * if the value is preceded by a `!` checks that the value is not in the list
## * if the value is succeeded by a `?` the value may or may not be contained
##
## returns true if all queries match
## 
function(list_check_items __lst)
  set(lst ${${__lst}})
  set(result 0)
  list(LENGTH ARGN len)

  foreach(item ${ARGN})
    set(negate false)
    set(optional false)
    if("${item}" MATCHES "^!(.+)$")
      set(item "${CMAKE_MATCH_1}")
      set(negate true)
    endif()
    if("${item}" MATCHES "^(.+)\\?$")
      set(item "${CMAKE_MATCH_1}")
      set(optional true)
    endif()

    list_contains(lst "${item}")
    ans(is_contained)

    if(false)
    elseif(    is_contained AND     negate AND     optional)
      list_remove(lst "${item}")
    elseif(    is_contained AND     negate AND NOT optional)
      return(false)
    elseif(    is_contained AND NOT negate AND     optional)
      list_remove(lst "${item}")
    elseif(    is_contained AND NOT negate AND NOT optional)
      list_remove(lst "${item}")
    elseif(NOT is_contained AND     negate AND     optional)
      list_remove(lst "${item}")
    elseif(NOT is_contained AND     negate AND NOT optional)
      list_remove(lst "${item}")
    elseif(NOT is_contained AND NOT negate AND     optional)
      list_remove(lst "${item}")
    elseif(NOT is_contained AND NOT negate AND NOT optional)
      return()
    endif()

   # print_vars(lst item is_contained negate optional)
  endforeach()

  list(LENGTH lst len)
  if(len)
    return(false)
  endif()
  return(true)
endfunction()




## `(<list&...>)-><any...>`
##
## returns all possible combinations of the specified lists
## e.g.
## ```
## set(range 0 1)
## list_combinations(range range range)
## ans(result)
## assert(${result} EQUALS 000 001 010 011 100 101 110 111)
## ```
##
function(list_combinations)
  set(lists ${ARGN})
  list_length(lists)
  ans(len)

  if(${len} LESS 1)
    return()
  elseif(${len} EQUAL 1)
    return_ref(${lists})
  elseif(${len} EQUAL 2)
    list_extract(lists __listA __listB)
    set(__result)
    foreach(elementA ${${__listA}})
      foreach(elementB ${${__listB}})
        list(APPEND __result "${elementA}${elementB}")
      endforeach()
    endforeach()
    return_ref(__result)
  else()
    list_pop_front(lists)
    ans(___listA)

    list_combinations(${lists})
    ans(___listB)

    list_combinations(${___listA} ___listB)
    return_ans()
  endif()
endfunction()




## `(<list&> <element:<any...>>)-><bool>`
##
## returns true if list contains every element specified 
##
function(list_contains __list_contains_lst)
	foreach(arg ${ARGN})
		list(FIND ${__list_contains_lst} "${arg}" idx)
		if(${idx} LESS 0)
			return(false)
		endif()
	endforeach()
	return(true)
endfunction()





function(list_contains_any __lst)
    if("${ARGC}" EQUAL "1")
    ## no items specified 
    return(true)
  endif()

  list(LENGTH ${__lst} list_len)
  if(NOT list_len)
    ## list is empty and items are specified -> list does not contain
    return(false)
  endif()


  foreach(item ${ARGN})
    list(FIND ${__lst} ${item} idx)
    if(idx GREATER -1)
      return(true)
    endif()

  endforeach() 
  return(false)
endfunction()




## `(<list&> <predicate:<[](<any>)-><bool>>> )-><uint>`
##
## counts all element for which the predicate holds 
function(list_count __list_count_lst __list_count_predicate)
  function_import("${__list_count_predicate}" as __list_count_predicate REDEFINE)
  set(__list_count_counter 0)
  foreach(__list_count_item ${${__list_count_lst}})
    __list_count_predicate("${__list_count_item}")
    ans(__list_count_match)
    if(__list_count_match)
      math(EXPR __list_count_counter "${__list_count_counter} + 1") 
    endif()
  endforeach()
  return("${__list_count_counter}")
endfunction()




# comapres two lists with each other
# usage
# list_equal( 1 2 3 4 1 2 3 4)
# list_equal( listA listB)
# list_equal( ${listA} ${listB})
# ...
# COMPARATOR defaults to STREQUAL
# COMPARATOR can also be a lambda expression
# COMPARATOR can also be EQUAL
function(list_equal)
	set(options)
  	set(oneValueArgs COMPARATOR)
  	set(multiValueArgs)
  	set(prefix)
  	cmake_parse_arguments("${prefix}" "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
	#_UNPARSED_ARGUMENTS


	# get length of both lists

	list(LENGTH _UNPARSED_ARGUMENTS count)



	#if count is exactly two input could be list references
	if(${count} EQUAL 2)
		list(GET _UNPARSED_ARGUMENTS 0 ____listA)
		list(GET _UNPARSED_ARGUMENTS 1 ____listB)
		if(DEFINED ${____listA} AND DEFINED ${____listB})
			# recursive call and return
			list_equal(  ${${____listA}} ${${____listB}} COMPARATOR "${_COMPARATOR}")
			return_ans()
		endif()

	endif()

	set(listA)
	set(listB)




	math(EXPR single_count "${count} / 2")
	math(EXPR is_even "${count} % 2")
	if(NOT ${is_even} EQUAL "0")
		#element count is not divisible by two so the lists cannot be equal
		# because they do not have the same length

		return(false)

	else()
		# split input arguments into two
		list_split(listA listB _UNPARSED_ARGUMENTS ${single_count})
	#message("${_UNPARSED_ARGUMENTS} => ${listA} AND ${listB}")
	endif()


	# set default comparator to strequal
	if(NOT _COMPARATOR)
		set(_COMPARATOR "STREQUAL")
	endif()

	# depending on the comparator
	if(${_COMPARATOR} STREQUAL "STREQUAL")
		set(lambda "[](a b) eval_truth('{{a}}' STREQUAL '{{b}}')")
	elseif(${_COMPARATOR} STREQUAL "EQUAL")
		set(lambda "[](a b) eval_truth('{{a}}' EQUAL '{{b}}')")
	else()
		set(lambda "${_COMPARATOR}")
	endif()
	# import function string 
	function_import("${lambda}" as __list_equal_comparator REDEFINE)
		
	set(res)
	# compare list
	math(EXPR single_count "${single_count} - 1")
	foreach(i RANGE ${single_count})
		list(GET listA ${i} a)
		list(GET listB ${i} b)
		#message("comparing ${a} ${b}")
		__list_equal_comparator(${a} ${b})
		ans(res)
		if(NOT res)
			return(false)
		endif()
	endforeach()
	return(true)

endfunction()




# removes the specified range from lst the start_index is inclusive and end_index is exclusive
#
macro(list_erase __list_erase_lst start_index end_index)
  list_without_range(${__list_erase_lst} ${start_index} ${end_index})
  ans(${__list_erase_lst})
endmacro()




# removes the specified range from lst and returns the removed elements
macro(list_erase_slice __list_erase_slice_lst start_index end_index)
  list_slice(${__list_erase_slice_lst} ${start_index} ${end_index})
  ans(__res)

  list_without_range(${__list_erase_slice_lst} ${start_index} ${end_index})
  ans(${__list_erase_slice_lst})
  set(__ans ${__res})
  #set(${__list_erase_slice_lst} ${rest} PARENT_SCOPE)
  #return_ref(res)
endmacro()








# return those elemnents of minuend that are not in subtrahend
function(list_except __list_except_minuend list_except_subtrahend)
	set(__list_except_result)
	foreach(__list_except_current ${${__list_except_minuend}})
		list(FIND ${list_except_subtrahend} "${__list_except_current}" __list_except_idx)
		if(${__list_except_idx} LESS 0)
			list(APPEND __list_except_result ${__list_except_current})
		endif()
	endforeach()
  return_ref(__list_except_result)
endfunction()




# extracts elements from the list
# example
# set(lst 1 2  )
# list_extract(lst a b c)
# a contains 1
# b contains 2
# c contains nothing
# returns the rest of list
function(list_extract __list_extract_lst)
  set(__list_extract_list_tmp ${${__list_extract_lst}})
  set(args ${ARGN})
  while(true)
    list_pop_front( args)
    ans(current_arg)
    if(NOT current_arg)
      break()
    endif()
    list_pop_front( __list_extract_list_tmp)
    ans(current_value)
    set(${current_arg} ${current_value} PARENT_SCOPE)
  endwhile()
  return_ref(__list_extract_list_tmp)
endfunction()










# extracts all of the specified flags and returns true if any of them were found
function(list_extract_any_flag __list_extract_any_flag_lst)
  list_extract_flags("${__list_extract_any_flag_lst}" ${ARGN})
  set("${__list_extract_any_flag_lst}" ${${__list_extract_any_flag_lst}} PARENT_SCOPE)
  ans(flag_map)
  map_keys(${flag_map})
  ans(found_keys)
  list(LENGTH found_keys len)
  if(${len} GREATER 0)
    return(true)
  endif()
  return(false)
endfunction()







## extracts any of the specified labelled values and returns as soon 
## the first labelled value is found
## lst contains its original elements without the labelled value 
function(list_extract_any_labelled_value __list_extract_any_labelled_value_lst)
  set(__list_extract_any_labelled_value_res)
  foreach(label ${ARGN})
    list_extract_labelled_value(${__list_extract_any_labelled_value_lst} ${label})
    ans(__list_extract_any_labelled_value_res)
    if(NOT "${__list_extract_any_labelled_value_res}_" STREQUAL "_")    
      break()
    endif()
  endforeach()
  set(${__list_extract_any_labelled_value_lst} ${${__list_extract_any_labelled_value_lst}}  PARENT_SCOPE)
  return_ref(__list_extract_any_labelled_value_res)
endfunction()





  #extracts a single flag from a list returning true if it was found
  # false otherwise. 
  # if flag exists multiple time online the first instance of the flag is removed
  # from the list
 function(list_extract_flag __list_extract_flag flag)
    list(FIND "${__list_extract_flag}" "${flag}" idx)
    if(${idx} LESS 0)
      return(false)     
    endif()
    list(REMOVE_AT "${__list_extract_flag}" "${idx}") 
    set("${__list_extract_flag}" "${${__list_extract_flag}}" PARENT_SCOPE)
    return(true)
endfunction()







# extracts all flags specified and returns a map with the key being the flag name if it was found and the value being set to tru
# e.g. list_extract_flags([a,b,c,d] a c e) -> {a:true,c:true}, [b,d]
function(list_extract_flags __list_extract_flags_lst)
  list_find_flags("${__list_extract_flags_lst}" ${ARGN})
  ans(__list_extract_flags_flag_map)
  map_keys(${__list_extract_flags_flag_map})
  ans(__list_extract_flags_found_flags)
  list_remove("${__list_extract_flags_lst}" ${__list_extract_flags_found_flags})
 # list(REMOVE_ITEM "${__list_extract_flags_lst}" ${__list_extract_flags_found_flags})
  set("${__list_extract_flags_lst}" ${${__list_extract_flags_lst}} PARENT_SCOPE)
  return(${__list_extract_flags_flag_map})
endfunction()





 ## extracts a flag from the list if it is found 
 ## returns the flag itself (usefull for forwarding flags)
  macro(list_extract_flag_name __lst __flag)
    list_extract_flag("${__lst}" "${__flag}")
    ans(__flag_was_found)
    set_ans("")
    if(__flag_was_found)
      if(NOT "${ARGN}_" STREQUAL "_")
        set_ans("${ARGN}")
      else()
        set_ans("${__flag}")
      endif()
    endif()
  endmacro()





    ## extracts a labelled key value (the label and the value if it exists)
    macro(list_extract_labelled_keyvalue __lst label)
      list_extract_labelled_value(${__lst} "${label}")
      ans(__lbl_value)
      if(NOT "${__lbl_value}_" STREQUAL "_")
        if(ARGN)
          set_ans("${ARGN};${__lbl_value}")
        else()
          set_ans("${label};${__lbl_value}")
        endif()
      else()
        set_ans("")
      endif()
    endmacro()




# searchs for label in lst. if label is found 
# the label and its following value is removed
# and returned
# if label is found but no value follows ${ARGN} is returned
# if following value is enclosed in [] the brackets are removed
# this allows mulitple values to be returned ie
# list_extract_labelled_value(lstA --test1)
# if lstA is a;b;c;--test1;[1;3;4];d
# the function returns 1;3;4
function(list_extract_labelled_value lst label)
  # return nothing if lst is empty
  list_length(${lst})
  ans(len)
  if(NOT len)
    return()
  endif()
  # find label in list
  list_find(${lst} "${label}")
  ans(pos)
  
  if("${pos}" LESS 0)
    return()
  endif()

  eval_math("${pos} + 2")
  ans(end)


  if(${end} GREATER ${len} )
    eval_math("${pos} + 1")
    ans(end)
  endif()

  list_erase_slice(${lst} ${pos} ${end})
  ans(vals)

  list_pop_front(vals)
  ans(flag)
    

  # special treatment for [] values
  if("_${vals}" MATCHES "^_\\[.*\\]$")
    string_slice("${vals}" 1 -2)
    ans(vals)
  endif()


  if("${vals}_" STREQUAL "_")
    set(vals ${ARGN})
  endif()

  
  set(${lst} ${${lst}} PARENT_SCOPE)


  return_ref(vals)
endfunction()





## `(<&> <regex>...)-><any...>`
##
## removes all matches from the list and returns them
## sideffect: matches are removed from list
function(list_extract_matches __list_extract_matches_lst)
  list_regex_match(${__list_extract_matches_lst} ${ARGN})
  ans(matches)
  list_remove(${__list_extract_matches_lst} ${matches})
  #print_vars(matches __list_extract_matches_lst ${__list_extract_matches_lst})
  set(${__list_extract_matches_lst} ${${__list_extract_matches_lst}} PARENT_SCOPE)
  return_ref(matches)
endfunction()




# searchs lst for value and returns the first idx found
# returns -1 if value is not found
function(list_find __list_find_lst value)
  if(NOT "${__list_find_lst}")
    return(-1)
  endif()
  list(FIND ${__list_find_lst} "${value}" idx)
  return_ref(idx)
endfunction()









## returns the index of the one of the specified items
## if no element is found then -1 is returned 
## no guarantee is made on which item's index
## is returned 
function(list_find_any __list_find_any_lst )
  foreach(__list_find_any_item ${ARGN})
    list(FIND ${__list_find_any_lst} ${__list_find_any_item} __list_find_any_idx)
    if(${__list_find_any_idx} GREATER -1)
      return(${__list_find_any_idx})
    endif()
  endforeach()
  return(-1)
endfunction()





## returns a map of all found flags specified as ARGN
##  
function(list_find_flags __list_find_flags_lst)
  map_new()
  ans(__list_find_flags_result)
  foreach(__list_find_flags_itm ${ARGN})
    list(FIND "${__list_find_flags_lst}" "${__list_find_flags_itm}" __list_find_flags_item)
    if(NOT "${__list_find_flags_item}" LESS 0)
      map_set(${__list_find_flags_result} "${__list_find_flags_itm}" true)
    endif()
  endforeach()
  return(${__list_find_flags_result})
endfunction()




# folds the specified list into a single result by recursively applying the aggregator
function(list_fold lst aggregator)
  if(NOT "_${ARGN}" STREQUAL _folding)
    function_import("${aggregator}" as __list_fold_folder REDEFINE)
  endif()
  set(rst ${${lst}})
  list_pop_front(rst)
  ans(left)
  
  if("${rst}_" STREQUAL "_")
    return(${left})
  endif()


  list_fold(rst "" folding)
  ans(right)
  __list_fold_folder("${left}" "${right}")

  ans(res)

 # message("left ${left} right ${right} => ${res}")
  return(${res})
endfunction()



## faster non recursive version
function(list_fold lst aggregator)
  if(NOT "_${ARGN}" STREQUAL _folding)
    function_import("${aggregator}" as __list_fold_folder REDEFINE)
  endif()

  set(rst ${${lst}})
  list_pop_front(rst)
  ans(left)
  
  if("${rst}_" STREQUAL "_")
    return(${left})
  endif()

  set(prev "${left}")
  foreach(item ${rst})
    __list_fold_folder("${prev}" "${item}")
    ans(prev)
  endforeach()
  return_ref(prev)



endfunction()





## returns the item at the specified index
## the index is normalized (see list_normalize_index)
function(list_get __list_get_lst idx)
  list_normalize_index("${__list_get_lst}" "${idx}")
  ans(index)
  list_length("${__list_get_lst}")
  ans(len)
  if("${index}" LESS 0 OR "${index}" GREATER "${len}")
    return()
  endif()
  list(GET ${__list_get_lst} "${index}" value)
  return_ref(value)
endfunction()




## gets the labelled value from the specified list
## set(thelist a b c d)
## list_get_labelled_value(thelist b) -> c
function(list_get_labelled_value __list_get_labelled_value_lst __list_get_labelled_value_value)
  list_extract_labelled_value(${__list_get_labelled_value_lst} ${__list_get_labelled_value_value} ${ARGN})
  return_ans()
endfunction()




# returns a list containing all elemmtns contained
# in all passed list references
function(list_intersect)
  set(__list_intersect_lists ${ARGN})

  list(LENGTH __list_intersect_lists __list_intersect_lists_length)
  if(NOT __list_intersect_lists_length)
    return()
  endif()

  if("${__list_intersect_lists_length}" EQUAL 1)
    if("${__list_intersect_lists}")
      list(REMOVE_DUPLICATES "${__list_intersect_lists}")
    endif()
    return_ref("${__list_intersect_lists}")
  endif()


  list_pop_front(__list_intersect_lists)
  ans(__list_intersect_first)
  list_intersect(${__list_intersect_first})
  ans(__list_intersect_current_elements)
  # __list_intersect_current_elements is now unique

  # intersect rest elements
  list_intersect(${__list_intersect_lists})
  ans(__list_intersect_rest_elements)

  # get elements which are to be removed from list
  set(__list_intersect_elements_to_remove ${__list_intersect_current_elements})
  if(__list_intersect_elements_to_remove)
    foreach(__list_operation_item ${__list_intersect_rest_elements})
      list(REMOVE_ITEM __list_intersect_elements_to_remove ${__list_operation_item})
    endforeach()  
  endif()
  # remove elements and return result
  if(__list_intersect_elements_to_remove)
    list(REMOVE_ITEM __list_intersect_current_elements ${__list_intersect_elements_to_remove})
  endif()
  return_ref(__list_intersect_current_elements)
endfunction()




# returns only those flags which are contained in list and in the varargs
# ie list = [--a --b --c --d]
# list_intersect_args(list --c --d --e) ->  [--c --d]
function(list_intersect_args __list_intersect_args_lst)
  set(__list_intersect_args_flags ${ARGN})
  list_intersect(${__list_intersect_args_lst} __list_intersect_args_flags)
  return_ans()
endfunction()




# checks if the given list reference is an empty list
  function(list_isempty __list_empty_lst)
    list(LENGTH  ${__list_empty_lst} len)
    if("${len}" EQUAL 0)
      return(true)
    endif()
    return(false)
  endfunction()




# returns true if value ${a} comes before value ${b} in list __list_isinorder_lst
# sets ${result} to true or false
function(list_isinorder  __list_isinorder_lst a b)
	list(FIND ${__list_isinorder_lst} ${a} indexA)
	list(FIND ${__list_isinorder_lst} ${b} indexB)
	if(${indexA} LESS 0)
		return(false)
	endif()
	if(${indexB} LESS 0)
		return(false)
	endif()
	if(${indexA} LESS ${indexB})
		return(true)
	endif()
	return(false)
endfunction()





## instanciates a list_iterator from the specified list
  function(list_iterator __list_ref)
    list(LENGTH ${__list_ref} __list_ref_len)
    return(${__list_ref} ${__list_ref_len} 0-1)
  endfunction()





## advances the iterator using list_iterator_next 
## and breaks the current loop when the iterator is done
macro(list_iterator_break it_ref)
  list_iterator_next(${it_ref})
  if(NOT __ans)
    break()
  endif()
endmacro()




## advances the iterator specified 
## and returns true if it is on a valid element (else false)
## sets the fields 
## ${it_ref}.index
## ${it_ref}.length
## ${it_ref}.list_ref
## ${it_ref}.value (only if a valid value exists)
function(list_iterator_next it_ref)
  list(GET ${it_ref} 0 list_ref)
  list(GET ${it_ref} 1 length)
  list(GET ${it_ref} 2 index)
  math(EXPR index "${index} + 1")    
  #print_vars(list_ref length index)
  set(${it_ref} ${list_ref} ${length} ${index} PARENT_SCOPE)
  set(${it_ref}.index ${index} PARENT_SCOPE)
  set(${it_ref}.length ${length} PARENT_SCOPE)
  set(${it_ref}.list_ref ${list_ref} PARENT_SCOPE)
  if(${index} LESS ${length})
    list(GET ${list_ref} ${index} value)
    set(${it_ref}.value "${value}" PARENT_SCOPE)
    return(true)
  else()
    set(${it_ref}.value PARENT_SCOPE)
    return(false)
  endif()
endfunction()





## returns the length of the specified list
macro(list_length __list_count_lst)
    list(LENGTH "${__list_count_lst}" __ans)
endmacro()





## returns the maximum value in the list 
## using the specified comparerer function
function(list_max lst comparer)
  list_fold(${lst} "${comparer}")
  ans(res)
  return(${res})
endfunction()






    
function(list_modify __list_name)
  set(args ${ARGN})
  list_extract_flag(args --append)
  ans(append)
  list_extract_flag(args --remove)
  ans(remove)
  list_extract_flag(args --sort)
  ans(sort)
  list_extract_flag(args --set)
  ans(set)
  list_extract_flag(args --get)
  ans(get)
  list_extract_labelled_value(args --insert)
  ans(insert)
  list_extract_labelled_value(args --remove-at)
  ans(remove_at)
  list_extract_flag(args --remove-duplicates)
  ans(remove_duplicates)

  set(value ${${__list_name}})

  list(LENGTH value length)

  if(NOT "${insert}_" STREQUAL "_")
    list(INSERT value ${insert} ${args})
  elseif(set)
    set(value ${args})
  elseif(append)
    list(APPEND value ${args})
  elseif(remove)
    list(REMOVE_ITEM value ${args})
  elseif(NOT "${remove_at}_" STREQUAL "_")
    list(REMOVE_AT value ${remove_at})
  else()

  endif()

  if(length)
    if(remove_duplicates)
      list(REMOVE_DUPLICATES value)
    endif()
    if(sort)
      list(SORT value)
    endif()
  endif()

  set(${__list_name} ${value} PARENT_SCOPE)
endfunction()




# returns the normalized index.  negative indices are transformed to i => length - i
# if the index is out of range after transformation -1 is returned and a warnign is issued
# note: index evaluating to length are valid (one behind last)
function(list_normalize_index __lst index )
  set(idx ${index})
  list(LENGTH ${__lst} length)

  if("${idx}" STREQUAL "*")
    set(idx ${length})
  endif()
  
  if(${idx} LESS 0)
    math(EXPR idx "${length} ${idx} + 1")
  endif()
  if(${idx} LESS 0)
    message(WARNING "index out of range: ${index} (${idx}) length of list '${lst}': ${length}")
    return(-1)
  endif()

  if(${idx} GREATER ${length})
    message(WARNING "index out of range: ${index} (${idx}) length of list '${lst}': ${length}")
    return(-1)
  endif()
  return(${idx})
endfunction()





# returns true if value could be parsed
function(list_parse_descriptor descriptor)  
  cmake_parse_arguments("" "" "UNUSED_ARGS;ERROR;CUTOFFS" "" ${ARGN})
  set(args ${_UNPARSED_ARGUMENTS})
  scope_import_map(${descriptor})
  list_find_any(args ${labels})
  ans(starting_index)

  list_slice(args 0 ${starting_index})
  ans(unused_args)
  list_slice(args ${starting_index} -1)
  ans(value_args)

  list_find_any(value_args ${${_CUTOFFS}})
  ans(cut_off)
  if(${cut_off} LESS 0)
    set(cut_off ${max})
  endif()
  math_min(${max} ${cut_off})
  ans(cut_off)

  #message(FORMAT "value args for {descriptor.id} max:${cut_off} are ${value_args} args: ${args}")

  # remove first arg as its the flag used to start this value
  list_pop_front( value_args)
  ans(used_label)
  
  # list length
  list(LENGTH value_args len)

  if("${cut_off}" STREQUAL "*")
    set(cut_off -1)
  endif()
  
  math_min(${len} ${cut_off})
  ans(cut_off)  
  list_slice(value_args "${cut_off}" -1)
  ans(tmp)

  list(APPEND unused_args ${tmp})

  # set result value for unused args
  if(_UNUSED_ARGS)
    set(${_UNUSED_ARGS} ${unused_args} PARENT_SCOPE)
  endif()
  
  list_slice(value_args 0 "${cut_off}")
  ans(value_args)

  # option
  if(${min} STREQUAL 0 AND ${max} STREQUAL 0)
    set(${_ERROR} false PARENT_SCOPE)
    if(starting_index LESS 0)
      return(false)
    else()
      return(true)
    endif()
  endif()

  # if less than min args are avaiable set error to true but
  # still return the found values however
  if(${cut_off} LESS ${min} )
    set(${_ERROR} true PARENT_SCOPE)
  else()
    set(${_ERROR} false PARENT_SCOPE)
  endif()


  # use return ref because value_args might return strange strings
  return_ref(value_args)

endfunction()




## Returns the last element of a list without modifying it
function(list_peek_back  __list_peek_back_lst)
  if("${${__list_peek_back_lst}}_" STREQUAL "_")
    return()
  endif()
  list(LENGTH ${__list_peek_back_lst} len)
  math(EXPR len "${len} - 1")
  list(GET ${__list_peek_back_lst} "${len}" res)
  return_ref(res)
endfunction()




# gets the first element of the list without modififying it
function(list_peek_front __list_peek_front_lst)
  if("${${__list_peek_front_lst}}_" STREQUAL "_")
    return()
  endif()
  list(GET "${__list_peek_front_lst}" 0 res)
  return_ref(res)
endfunction()




# removes the last element from list and returns it
function(list_pop_back __list_pop_back_lst)

  if("${${__list_pop_back_lst}}_" STREQUAL "_")
    return()
  endif()
  list(LENGTH "${__list_pop_back_lst}" len)
  math(EXPR len "${len} - 1")
  list(GET "${__list_pop_back_lst}" "${len}" res)
  list(REMOVE_AT "${__list_pop_back_lst}" ${len})
  set("${__list_pop_back_lst}" ${${__list_pop_back_lst}} PARENT_SCOPE)
  return_ref(res)
endfunction()



  # removes the last element from list and returns it
  ## faster version
macro(list_pop_back __list_pop_back_lst)
  if("${${__list_pop_back_lst}}_" STREQUAL "_")
    set(__ans)
  else()
    list(LENGTH "${__list_pop_back_lst}" __list_pop_back_length)
    math(EXPR __list_pop_back_length "${__list_pop_back_length} - 1")
    list(GET "${__list_pop_back_lst}" "${__list_pop_back_length}" __ans)
    list(REMOVE_AT "${__list_pop_back_lst}" ${__list_pop_back_length})
  endif()
endmacro()




# removes the first value of the list and returns it
function(list_pop_front  __list_pop_front_lst)
  set(res)

  list(LENGTH "${__list_pop_front_lst}" len)
  if("${len}" EQUAL 0)
    return()
  endif()

  list(GET ${__list_pop_front_lst} 0 res)

  if(${len} EQUAL 1) 
    set(${__list_pop_front_lst} )
  else()
    list(REMOVE_AT "${__list_pop_front_lst}" 0)
  endif()
  #message("${__list_pop_front_lst} is ${${__list_pop_front_lst}}")
#  set(${result} ${res} PARENT_SCOPE)
  set(${__list_pop_front_lst} ${${__list_pop_front_lst}} PARENT_SCOPE)
  return_ref(res)
endfunction()


# removes the first value of the list and returns it
## faster version
macro(list_pop_front  __list_pop_front_lst)
  list(LENGTH "${__list_pop_front_lst}" __list_pop_front_length)
  if(NOT "${__list_pop_front_length}" EQUAL 0)
    list(GET ${__list_pop_front_lst} 0 __ans)

    if(${__list_pop_front_length} EQUAL 1) 
      set(${__list_pop_front_lst})
    else()
      list(REMOVE_AT "${__list_pop_front_lst}" 0)
    endif()
  else()
    set(__ans)
  endif()

endmacro()




# adds a value to the end of the list
function(list_push_back __list_push_back_lst value)
  set(${__list_push_back_lst} ${${__list_push_back_lst}} ${value} PARENT_SCOPE)
endfunction()




# adds a value at the beginning of the list
function(list_push_front __list_push_front_lst value)
  set(${__list_push_front_lst} ${value} ${${__list_push_front_lst}} PARENT_SCOPE)   
  return(true)
endfunction()




## matches all elements of lst to regex
## all elements in list which match the regex are returned
function(list_regex_match __list_regex_match_lst )
  set(__list_regex_match_result)
  foreach(__list_regex_match_item ${${__list_regex_match_lst}})
    foreach(__list_regex_match_regex ${ARGN})
      if("${__list_regex_match_item}" MATCHES "${__list_regex_match_regex}")
        list(APPEND __list_regex_match_result "${__list_regex_match_item}")
        break() ## break inner loop on first match
      endif()
    endforeach()
  endforeach()
  return_ref(__list_regex_match_result)
endfunction()





## returns every element of lst that matches any of the given regexes
## and does not match any regex that starts with !
  function(list_regex_match_ignore lst)
    set(regexes ${ARGN})
    list_regex_match(regexes "^[!]")
    ans(negs)
    set(negatives)
    foreach(negative ${negs})
      string(SUBSTRING "${negative}" 1 -1 negative )
      list(APPEND negatives "${negative}")
    endforeach()

    list_regex_match(regexes "^[^!]")
    ans(positives)


    list_regex_match(${lst} ${positives})
    ans(matches)

    list_regex_match(matches ${negatives})
    ans(ignores)

    list(REMOVE_ITEM matches ${ignores})

    return_ref(matches)

  endfunction()





# removes all items specified in varargs from list
# returns the number of items removed
function(list_remove __list_remove_lst)
  list(LENGTH "${__list_remove_lst}" __lst_len)
  list(LENGTH ARGN __arg_len)
  if(__arg_len EQUAL 0 OR __lst_len EQUAL 0)
    return()
  endif()
  list(REMOVE_ITEM "${__list_remove_lst}" ${ARGN})
  list(LENGTH "${__list_remove_lst}" __lst_new_len)
  math(EXPR __removed_item_count "${__lst_len} - ${__lst_new_len}")
  set("${__list_remove_lst}" "${${__list_remove_lst}}" PARENT_SCOPE)
  return_ref(__removed_item_count)
endfunction()




# removes all items at all specified indices from list 
function(list_remove_at __list_remove_at_lst)
  if(NOT "${__list_remove_at_lst}")
    return()
  endif()
  set(args)

  foreach(arg ${ARGN})
      list_normalize_index(${__list_remove_at_lst} ${arg})
      ans(res)
      list(APPEND args ${res})
  endforeach()



  list(REMOVE_AT "${__list_remove_at_lst}" ${args})

  set("${__list_remove_at_lst}" "${${__list_remove_at_lst}}" PARENT_SCOPE)

  return_ref("${__list_remove_at_lst}")  

endfunction()




## removes duplicates from a list
function(list_remove_duplicates __lst)
  list(LENGTH ${__lst} len)
  if(len EQUAL 0)
    return()
  endif()
  list(REMOVE_DUPLICATES ${__lst})
  set(${__lst} ${${__lst}} PARENT_SCOPE)
  return()
endfunction()





# replaces lists  value at i with new_value
function(list_replace_at __list_replace_at_lst i new_value)
  list(LENGTH ${__list_replace_at_lst} len)
  if(NOT "${i}" LESS "${len}")
    return(false)
  endif()
  list(INSERT ${__list_replace_at_lst} ${i} ${new_value}) 
  math(EXPR i_plusone "${i} + 1" )
  list(REMOVE_AT ${__list_replace_at_lst} ${i_plusone})
  set(${__list_replace_at_lst} ${${__list_replace_at_lst}} PARENT_SCOPE)
  return(true)
endfunction()






  ## replaces the specified slice with the specified varargs
  ## returns the elements which were removed
  function(list_replace_slice __list_ref __start_index __end_index)
    ## normalize indices
    list_normalize_index(${__list_ref} ${__start_index})
    ans(__start_index)
    list_normalize_index(${__list_ref} ${__end_index})
    ans(__end_index)


    list(LENGTH ARGN __insert_count)
    ## add new elements
    if(__insert_count)
      list(LENGTH ${__list_ref} __old_length)
      if("${__old_length}" EQUAL "${__start_index}")
        list(APPEND ${__list_ref} ${ARGN})
      else()
        list(INSERT ${__list_ref} ${__start_index} ${ARGN})
      endif()
      math(EXPR __start_index "${__start_index} + ${__insert_count}")
      math(EXPR __end_index "${__end_index} + ${__insert_count}")
    endif()
    
    ## generate index list of elements to remove
    index_range(${__start_index} ${__end_index})
    ans(__indices)

    ## get number of elements to remove
    list(LENGTH __indices __remove_count)
    
    ## get slice which is to be removed and remove it
    set(__removed_elements)
    if(__remove_count)
      list(GET ${__list_ref} ${__indices} __removed_elements)
      list(REMOVE_AT ${__list_ref} ${__indices})
    endif()
    

    ## set result
    set(${__list_ref} ${${__list_ref}} PARENT_SCOPE)
    return_ref(__removed_elements)
  endfunction()




## `(<list ref>)-><void>`
##
## reverses the specified lists elements
macro(list_reverse __list_reverse_lst)
  if(${__list_reverse_lst})
    list(REVERSE ${__list_reverse_lst})
  endif()
endmacro()




# uses the selector on each element of the list
function(list_select __list_select_lst selector)
  list(LENGTH ${__list_select_lst} l)
  message(list_select ${l})
  set(__list_select_result_list)

  foreach(item ${${__list_select_lst}})
		rcall(res = "${selector}"("${item}"))
		list(APPEND __list_select_result_list ${res})

	endforeach()
  message("list_select end")
	return_ref(__list_select_result_list)
endfunction()



## fast implementation of list_select
function(list_select __list_select_lst __list_select_selector)
  function_import("${__list_select_selector}" as __list_select_selector REDEFINE)

  set(__res)
  set(__ans)
  foreach(__list_select_current_arg ${${__list_select_lst}})
    __list_select_selector(${__list_select_current_arg})
    list(APPEND __res ${__ans})
  endforeach()
  return_ref(__res)  
endfunction()





function(list_select_property __lst __prop)
  set(__result)
  foreach(__itm ${${__lst}})
    map_tryget("${__itm}" "${__prop}")
    ans(__res)
    list(APPEND __result "${__res}")
  endforeach()
  return_ref(__result)
endfunction()




# sets the lists value at index to the specified value
# the index is normalized -> negativ indices count down from back of list 
  function(list_set_at __list_set_lst index value)
    if("${index}" EQUAL -1)
      #insert element at end
      list(APPEND ${__list_set_lst} ${value})
      set(${__list_set_lst} ${${__list_set_lst}} PARENT_SCOPE)
      return(true)
    endif()
    list_normalize_index(${__list_set_lst} "${index}")
    ans(index)
    if(index LESS 0)
      return(false)
    endif()
    list_replace_at(${__list_set_lst} "${index}" "${value}")

    set(${__list_set_lst} ${${__list_set_lst}} PARENT_SCOPE)
    return(true)
  endfunction()




# retruns a portion of the list specified.
# negative indices count from back of list 
#
function(list_slice __list_slice_lst start_index end_index)
  # indices equal => select nothing

  list_normalize_index(${__list_slice_lst} ${start_index})
  ans(start_index)
  list_normalize_index(${__list_slice_lst} ${end_index})
  ans(end_index)

  if(${start_index} LESS 0)
    message(FATAL_ERROR "list_slice: invalid start_index ")
  endif()
  if(${end_index} LESS 0)
    message(FATAL_ERROR "list_slice: invalid end_index")
  endif()
  # copy array
  set(res)
  index_range(${start_index} ${end_index})
  ans(indices)

  list(LENGTH indices indices_len)
  if(indices_len)
    list(GET ${__list_slice_lst} ${indices} res)
  endif()
  #foreach(idx ${indices})
   # list(GET ${__list_slice_lst} ${idx} value)
    #list(APPEND res ${value})
   # message("getting value at ${idx} from ${${__list_slice_lst}} : ${value}")
  #endforeach()
 # message("${start_index} - ${end_index} : ${indices} : ${res}" )
  return_ref(res)
endfunction()








# orders a list by a comparator function
function(list_sort __list_order_lst comparator)
  list(LENGTH ${__list_order_lst} len)

  function_import("${comparator}" as __compare REDEFINE)

  # copyright 2014 Tobias Becker -> triple s "slow slow sort"
  set(i 0)
  set(j 0)
  while(true)
    if(NOT ${i} LESS ${len})
      set(i 0)
      math(EXPR j "${j} + 1")
    endif()

    if(NOT ${j} LESS ${len}  )
      break()
    endif()
    list(GET ${__list_order_lst} ${i} a)
    list(GET ${__list_order_lst} ${j} b)
    #rcall(res = "${comparator}"("${a}" "${b}"))
    __compare("${a}" "${b}")
    ans(res)
    if(res LESS 0)
      list_swap(${__list_order_lst} ${i} ${j})
    endif()


    math(EXPR i "${i} + 1")
  endwhile()
  return_ref(${__list_order_lst})
endfunction()

## faster implementation: quicksort


# orders a list by a comparator function and returns it
function(list_sort __list_sort_lst comparator)
  list(LENGTH ${__list_sort_lst} len)
  math(EXPR len "${len} - 1")
  function_import("${comparator}" as __quicksort_compare REDEFINE)
  __quicksort(${__list_sort_lst} 0 ${len})
  return_ref(${__list_sort_lst})
endfunction()

   ## the quicksort routine expects a function called 
   ## __quicksort_compare to be defined
 macro(__quicksort __list_sort_lst lo hi)
  if("${lo}" LESS "${hi}")
    ## choose pivot
    set(p_idx ${lo})
    ## get value of pivot 
    list(GET ${__list_sort_lst} ${p_idx} p_val)
    
    list_swap(${__list_sort_lst} ${p_idx} ${hi})
    math(EXPR upper "${hi} - 1")
    
    ## store index p
    set(p ${lo})
    foreach(i RANGE ${lo} ${upper})
      list(GET ${__list_sort_lst} ${i} c_val)
      __quicksort_compare("${c_val}" "${p_val}")
      ans(cmp)
      if("${cmp}" GREATER 0)
        list_swap(${__list_sort_lst} ${p} ${i})
        math(EXPR p "${p} + 1")
      endif()
    endforeach()
    list_swap(${__list_sort_lst} ${p} ${hi})

    math(EXPR p_lo "${p} - 1")
    math(EXPR p_hi "${p} + 1")
    ## recursive call
    __quicksort("${__list_sort_lst}" "${lo}" "${p_lo}")
    __quicksort("${__list_sort_lst}" "${p_hi}" "${hi}")
  endif()
 endmacro()





## assert allows assertion

# splits a list into two parts after the specified index
# example:
# set(lst 1 2 3 4 5 6 7)
# list_split(p1 p2 lst 3)
# p1 will countain 1 2 3
# p2 will contain 4 5 6 7
function(list_split part1 part2 _lst index)
	list(LENGTH ${_lst} count)
	#message("${count} ${${_lst}}")
	# subtract one because range goes to index count and should only got to count -1
	math(EXPR count "${count} -1")
	set(p1)
	set(p2)
	foreach(i RANGE ${count})
		#message("${i}")
		list(GET ${_lst} ${i} val)
		if(${i} LESS ${index} )
			list(APPEND p1 ${val})
		else()
			list(APPEND p2 ${val})
		endif()
	endforeach()
	set(${part1} ${p1} PARENT_SCOPE)
	set(${part2} ${p2} PARENT_SCOPE)
	return()
endfunction()








## list_split_at()
##
##
function(list_split_at lhs rhs __lst key)
  list(LENGTH ${__lst} len)
  if(NOT len)
    set(${lhs} PARENT_SCOPE)
    set(${rhs} PARENT_SCOPE)
    return()
  endif()

  list(FIND ${__lst} ${key} idx)

  list_split(${lhs} ${rhs} ${__lst} ${idx})

  set(${lhs} ${${lhs}} PARENT_SCOPE)
  set(${rhs} ${${rhs}} PARENT_SCOPE)

  return()
endfunction()




# swaps the element of lst at i with element at index j
macro(list_swap __list_swap_lst i j)
	list(GET ${__list_swap_lst} ${i} a)
	list(GET ${__list_swap_lst} ${j} b)
	list_replace_at(${__list_swap_lst} ${i} ${b})
	list_replace_at(${__list_swap_lst} ${j} ${a})
endmacro()







  function(list_to_map lst key_selector)
    function_import("${key_selector}" as __to_map_key_selector REDEFINE)
    map_new()
    ans(res)
    foreach(item ${${lst}})
      __to_map_key_selector(${item})
      ans(key)
      map_set(${res} "${key}" "${item}")
    endforeach()
    return_ref(res)

  endfunction()







# Converts a CMake list to a string containing elements separated by spaces
function(list_to_string  list_name separator )
  set(res)
  set(current_separator)
  foreach(element ${${list_name}})
    set(res "${res}${current_separator}${element}")
    # after first iteration separator will be set correctly
    # so i do not need to remove initial separator afterwords
    set(current_separator ${separator})
  endforeach()
  return_ref(res)

endfunction()




# returns a list containing the unqiue set of all elements
# contained in passed list referencese
function(list_union)
  if(NOT ARGN)
    return()
  endif()
  set(__list_union_result)
  foreach(__list_union_list ${ARGN})
    list(APPEND __list_union_result ${${__list_union_list}})
  endforeach() 

  list(REMOVE_DUPLICATES __list_union_result)
  return_ref(__list_union_result)
endfunction()





# takes the passed list and returns only its unique elements
# see cmake's list(REMOVE_DUPLICATES)
function(list_unique __list_unique_lst)
  list(LENGTH ${__list_unique_lst} __len)
  if(${__len} GREATER 1)
	 list(REMOVE_DUPLICATES ${__list_unique_lst})
  endif()
	return_ref(${__list_unique_lst})
endfunction()





# executes a predicate on every item of the list (passed by reference)
# and returns those items for which the predicate holds
function(list_where __list_where_lst predicate)

	foreach(item ${${__list_where_lst}})
    rcall(__matched = "${predicate}"("${item}"))
		if(__matched)
			list(APPEND result_list ${item})
		endif()
	endforeach()
	return_ref(result_list)
endfunction()


## fast implemenation
function(list_where __list_where_lst __list_where_predicate)
  function_import("${__list_where_predicate}" as __list_where_predicate REDEFINE)
  set(__list_where_result_list)
  foreach(__list_where_item ${${__list_where_lst}})
    __list_where_predicate(${__list_where_item})
    ans(__matched)
    if(__matched)
      list(APPEND __list_where_result_list ${__list_where_item})
    endif()
  endforeach()
  return_ref(__list_where_result_list)
endfunction()





# removes the specifed range from the list
# and returns remaining elements
function(list_without_range __list_without_range_lst start_index end_index)

  list_normalize_index(${__list_without_range_lst} -1)
  ans(list_end)

  list_slice(${__list_without_range_lst} 0 ${start_index})
  ans(part1)
  list_slice(${__list_without_range_lst} ${end_index} ${list_end})
  ans(part2)

  set(res ${part1} ${part2})
  return_ref(res)
endfunction()





## returns the elements of the specified list ref which are indexed by specified range
function(list_range_get __lst_ref)
  list(LENGTH ${__lst_ref} __len)
  range_indices("${__len}" ${ARGN})
  ans(__indices)
  list(LENGTH __indices __len)
  if(NOT __len)
    return()
  endif()
  list(GET ${__lst_ref} ${__indices} __res)
  return_ref(__res)
endfunction()






  ## list_range_indices(<list&> <range ...>)
  ## returns the indices for the range for the specified list
  ## e.g. 
  ## 
  function(list_range_indices __lst)
    list(LENGTH ${__lst} len)
    range_indices("${len}" ${ARGN})
    ans(indices)
    return_ref(indices)
  endfunction()






## writes the specified varargs to the list
## at the beginning of the specified partial range
## fails if the range is a  multi range
## e.g. 
## set(lstB a b c)
## list_range_partial_write(lstB "[]" 1 2 3)
## -> lst== [a b c 1 2 3]
## list_range_partial_write(lstB "[1]" 1 2 3)
## -> lst == [a 1 2 3 c]
## list_range_partial_write(lstB "[1)" 1 2 3)
## -> lst == [a 1 2 3 b c]
  function(list_range_partial_write __lst __range)
    range_parse("${__range}")
    ans(partial_range)
    list(LENGTH partial_range len)
    if("${len}" GREATER 1)
      message(FATAL_ERROR "only partial partial_range allowed")
      return()
    endif()
   # print_vars(partial_range)

    string(REPLACE ":" ";" partial_range "${partial_range}")
    list(GET partial_range 0 begin)
    list(GET partial_range 1 end)

    if("${begin}" STREQUAL "n" AND "${end}" STREQUAL "n")
      set(${__lst} ${${__lst}} ${ARGN} PARENT_SCOPE)
      return()
    endif()

    list_range_remove("${__lst}" "${__range}")

    list(LENGTH ARGN insertion_count)
    if(NOT insertion_count)
      set(${__lst} ${${__lst}} PARENT_SCOPE)
      return()
    endif() 

    list(GET partial_range 6 reverse)
    if(reverse)
      set(insertion_index "${end}")
    else()
      set(insertion_index "${begin}")
    endif()

    list(LENGTH ${__lst} __len)
    if("${insertion_index}" LESS ${__len})
      list(INSERT ${__lst} "${insertion_index}" ${ARGN})
    elseif("${insertion_index}" EQUAL ${__len})
      list(APPEND ${__lst} ${ARGN})
    else()
      message(FATAL_ERROR "list_range_partial_write could not write to index ${insertion_index}")
    endif()


    set(${__lst} ${${__lst}} PARENT_SCOPE)
    return()
  endfunction()




## removes the specified range from the list
function(list_range_remove __lst range)
  list(LENGTH ${__lst} list_len)
  range_indices(${list_len} "${range}")
  ans(indices)
  list(LENGTH indices len)

  if(NOT len)
    return(0)
  endif()
  #message("${indices} - ${list_len}")
  if("${indices}" EQUAL ${list_len})
    return(0)
  endif()
  list(REMOVE_AT ${__lst} ${indices})
  set(${__lst} ${${__lst}} PARENT_SCOPE)
  return(${len})
endfunction()





  ## replaces the specified range with the specified arguments
  ## the varags are taken and fill up the range to replace_count
  ## e.g. set(list a b c d e) 
  ## list_range_replace(list "4 0 3:1:-2" 1 2 3 4 5) --> list is equal to  2 4 c 3 1 
  ##
  function(list_range_replace lst_ref range)
    set(lst ${${lst_ref}})

    list(LENGTH lst len)
    range_instanciate(${len} "${range}")
    ans(range)

    set(replaced)
    message("inputlist '${lst}' length : ${len} ")
    message("range: ${range}")
    set(difference)

    range_indices("${len}" ":")
    ans(indices)
    
    range_indices("${len}" "${range}")
    ans(indices_to_replace)
    
    list(LENGTH indices_to_replace replace_count)
    message("indices_to_replace '${indices_to_replace}' count: ${replace_count}")

    math(EXPR replace_count "${replace_count} - 1")

    if(${replace_count} LESS 0)
      message("done\n")
      return()
    endif()

    set(args ${ARGN})
    set(replaced)

    message_indent_push()
    foreach(i RANGE 0 ${replace_count})
      list(GET indices_to_replace ${i} index)

      list_pop_front(args)
      ans(current_value)

      #if(${i} EQUAL ${replace_count})
      #  set(current_value ${args})
      #endif()

      if(${index} GREATER ${len})
        message(FATAL_ERROR "invalid index '${index}' - list is only ${len} long")
      elseif(${index} EQUAL ${len}) 
        message("appending to '${current_value}' to list")
        list(APPEND lst "${current_value}")
      else()
        list(GET lst ${index} val)
        list(APPEND replaced ${val})
        message("replacing '${val}' with '${current_value}' at '${index}'")
        list(INSERT lst ${index} "${current_value}")
        #list(LENGTH current_value current_len)
        math(EXPR index "${index} + 1")
        list(REMOVE_AT lst ${index})
        message("list is now ${lst}")
      endif()



    endforeach()
    message_indent_pop()


    message("lst '${lst}'")
    message("replaced '${replaced}'")
    message("done\n")
    set(${lst_ref} ${lst} PARENT_SCOPE)
    return_ref(replaced)
  endfunction()




  ## sets every element included in range to specified value
  ## 
  function(list_range_set __lst __range __value)
    list_range_indices(${__lst} "${__range}")
    ans(indices)
    foreach(i ${indices})
      list(INSERT "${__lst}" "${i}" "${__value}")
      math(EXPR i "${i} + 1")
      list(REMOVE_AT "${__lst}" "${i}")
    endforeach()
    set(${__lst} ${${__lst}} PARENT_SCOPE)
    return()
  endfunction()






## returns the elements of the specified list ref which are indexed by specified range
  function(list_range_try_get __lst_ref)
    list(LENGTH ${__lst_ref} __len)
    range_indices("${__len}" ${ARGN})
    ans(__indices2)

    set(__indices)
    foreach(__idx ${__indices2})
      if(NOT ${__idx} LESS 0 AND ${__idx} LESS ${__len} )
        list(APPEND __indices ${__idx})
      endif()
    endforeach()

    list(LENGTH __indices __len)
    if(NOT __len)
      return()
    endif()
    list(GET ${__lst_ref} ${__indices} __res)
    return_ref(__res)
  endfunction()





## `(<index:<uint>...>)-><instanciated range...>`
## 
## returns the best ranges from the specified indices
## e.g range_from_indices(1 2 3) -> [1:3]
##     range_from_indices(1 2) -> 1 2
##     range_from_indices(1 2 3 4 5 6 7 8 4 3 2 1 9 6 7) -> [1:8] [4:1:-1] 9 6 7
function(range_from_indices)
  set(range)
  set(prev)
  set(begin -1)
  set(end -1)
  set(increment)
  list(LENGTH ARGN index_count)
  if(${index_count} EQUAL 0)
    return()
  endif() 


  set(indices_in_partial_range)
  foreach(i ${ARGN})
    if("${begin}"  EQUAL -1)
      set(begin ${i})
      set(end ${i})
    endif()


    if(NOT increment)
      math(EXPR increment "${i} - ${begin}")
      if( ${increment} GREATER 0)
        set(increment "+${increment}")
      elseif(${increment} EQUAL 0)
        set(increment)
      endif()
    endif()

    if(increment)
      math(EXPR expected "${end}${increment}")    
    else()
      set(expected ${i})
    endif()


    if(NOT ${expected} EQUAL ${i})
      __range_from_indices_create_range()
      ## end of current range
      set(begin ${i})
      set(increment)
      set(indices_in_partial_range)

    endif()
    set(end ${i}) 
    list(APPEND indices_in_partial_range ${i})
  endforeach()

  __range_from_indices_create_range()
  


  string(REPLACE ";" " " range "${range}")
  #message("res '${range}'")
  return_ref(range)
endfunction()

## helper macro
macro(__range_from_indices_create_range)
    list(LENGTH indices_in_partial_range number_of_indices)
 #   message("done with range: ${begin} ${end} ${increment} ${number_of_indices}")

    if(${number_of_indices} EQUAL 2)
      list(APPEND range "${begin}")
      list(APPEND range "${end}")
    elseif("${begin}" EQUAL "${end}")
      list(APPEND range "${begin}")
    elseif("${increment}" EQUAL 1)
      list(APPEND range "[${begin}:${end}]")
    else()
      math(EXPR increment "0${increment}")
      list(APPEND range "[${begin}:${end}:${increment}]")
    endif()
endmacro()




## `(<length:<int>> <~range...>)-><index:<uint>...>` 
##
## returns the list of indices for the specified range
## length may be negative which causes a failure if any anchors are used (`$` or `n`) 
## 
## if the length is valid  (`>-1`) only valid indices are returned or failure occurs
##
## a length of 0 always returns no indices
##
## **Examples**
## ```
## ```
function(range_indices length)

  if("${length}" EQUAL 0)
    return()
  endif()
  if("${length}" LESS 0)
    set(length 0)
  endif()
  
  range_instanciate("${length}" ${ARGN})
  ans(range)

  ## foreach partial range in range 
  ## get the begin and end and increment 
  ## use cmake's foreach loop to enumerate the range 
  ## and save the indices 
  ## remove a index at front and or back if the inclusivity warrants it
  ## return the indices
  set(indices)
  foreach(partial ${range})
    string(REPLACE ":" ";" partial "${partial}")
    list(GET partial 0 1 2 partial_range)
    foreach(i RANGE ${partial_range})
      list(APPEND indices ${i})
    endforeach() 
    list(GET partial 3 begin_inclusivity)
    list(GET partial 4 end_inclusivity)
    if(NOT end_inclusivity)
      list_pop_back(indices)
    endif()
    if(NOT begin_inclusivity)
      list_pop_front(indices)
    endif()
  endforeach()
  return_ref(indices)
endfunction()





## `(<length:<int>> <~range...>)-><instanciated range...>`
## 
## instanciates a range.  A uninstanciated range contains anchors
## these are removed when a length is specified (`n`)
## returns a valid range  with no anchors
function(range_instanciate length)
  range_parse(${ARGN})
  ans(range)

  if(${length} LESS 0)
    set(length 0)
  endif()

  math(EXPR last "${length}-1")

  set(result)
  foreach(part ${range})
    string(REPLACE : ";" part ${part})
    set(part ${part})
    list(GET part 0 begin)
    list(GET part 1 end)
    list(GET part 2 increment)
    list(GET part 3 begin_inclusivity)
    list(GET part 4 end_inclusivity)
    list(GET part 5 range_length)
    list(GET part 6 reverse)

    string(REPLACE "n" "${length}" range_length "${range_length}")
    string(REPLACE "$" "${last}" range_length "${range_length}")

    math(EXPR range_length "${range_length}")


    string(REPLACE "n" "${length}" end "${end}")
    string(REPLACE "$" "${last}" end "${end}")

    math(EXPR end "${end}")
    if(${end} LESS 0)
      message(FATAL_ERROR "invalid range end: ${end}")
    endif()

    string(REPLACE "n" "${length}" begin "${begin}")
    string(REPLACE "$" "${last}" begin "${begin}")
    math(EXPR begin "${begin}")
    if(${begin} LESS 0)
      message(FATAL_ERROR "invalid range begin: ${begin}")
    endif()

    list(APPEND result "${begin}:${end}:${increment}:${begin_inclusivity}:${end_inclusivity}:${range_length}:${reverse}")  
  endforeach()
 # message("res ${result}")
  return_ref(result)
endfunction()





## `(<~range...>)-><range>`
##
## parses a range string and normalizes it to have the following form:
## `<range> ::= <begin>":"<end>":"<increment>":"<begin inclusivity:<bool>>":"<end inclusivity:<bool>>":"<length>":"<reverse:<bool>>
## these `<range>`s can be used to generate a index list which can in turn be used to address lists.
##  
##   * a list of `<range>`s is a  `<range>`  
##   * `$` the last element 
##   * `n` the element after the last element ($+1)
##   * `-<n>` a begin or end starting with `-` is transformed into `$-<n>`
##   * `"["` `"("` `")"` and `"]"`  signify the inclusivity.  
## 
function(range_parse)
  ## normalize input by replacing certain characters
  string(REPLACE " " ";" range "${ARGN}")
  string(REPLACE "," ";" range "${range}")

  string(REPLACE "(" ">" range "${range}")
  string(REPLACE ")" "<" range "${range}")
  string(REPLACE "[" "<" range "${range}")
  string(REPLACE "]" ">" range "${range}")

  ## if there is more than one range group 
  ## recursively invoke range_parse
  list(LENGTH range group_count)
  set(ranges)
  if(${group_count} GREATER 1)
    foreach(group ${range})
      range_parse("${group}")
      ans(current)
      list(APPEND ranges "${current}")
    endforeach()
    return_ref(ranges)
  endif()


  ## get begin and end_inclusivity chars
  ## results in begin_inclusivity and end_inclusivity to be either "<" ">" or " "
  string(REGEX REPLACE "([^<>])+" "_" inclusivity "${range}")
  set(inclusivity "${inclusivity}___")
  string(SUBSTRING ${inclusivity} 0 1 begin_inclusivity )
  string(SUBSTRING ${inclusivity} 1 1 end_inclusivity )
  string(SUBSTRING ${inclusivity} 2 1 three )
  if(${end_inclusivity} STREQUAL _)
    set(end_inclusivity ${three})
  endif()


  ## transform "<" ">" and " " to a true or false value
  ## " " means default inclusivity
  set(default_begin_inclusivity)
  set(default_end_inclusivity)

  if("${begin_inclusivity}" STREQUAL "<")
    set(begin_inclusivity true)
  elseif("${begin_inclusivity}" STREQUAL ">")
    set(begin_inclusivity false)
  else()
   set(begin_inclusivity true)
   set(default_begin_inclusivity true) 
  endif()

  if("${end_inclusivity}" STREQUAL "<")
    set(end_inclusivity false)
  elseif("${end_inclusivity}" STREQUAL ">")
    set(end_inclusivity true)
  else()
    set(end_inclusivity true)
    set(default_end_inclusivity true)
  endif()

  ## remove all angular brackets from current range
  string(REGEX REPLACE "[<>]" "" range "${range}")

  ## default range for emtpy range (n:n)
  if("${range}_" STREQUAL "_")
    set(range "n:n:1")
    if(default_end_inclusivity)
      set(end_inclusivity false)
    endif()
  endif()

  ## default range for * 0:n
  if("${range}" STREQUAL "*")
    set(range "0:n:1")
  endif()

  ##  default range for  : 0:$
  if("${range}" STREQUAL ":")
    set(range "0:$:1")
  endif()

  ## split list at ":"
  string(REPLACE  ":" ";" range "${range}")
  
  ## normalize range and simplify elements
  

  ## single number is transformed to i;i;1 
  list(LENGTH range part_count)
  if(${part_count} EQUAL 1)
    set(range ${range} ${range} 1)
  endif()

  ## 2 numbers is autocompleted to  i;j;1
  if(${part_count} EQUAL 2)
    list(APPEND range 1)
  endif()

  ## now every range has 3 number begin end and increment
  list(GET range 0 begin)
  list(GET range 1 end)
  list(GET range 2 increment)

  ## if part count is higher than 3 the begin_inclusivity is specified
  if(${part_count} GREATER 3)
    list(GET range 3 begin_inclusivity)
  endif()
  ## if part count is higher than 4 the end_inclusivity is specified
  if(${part_count} GREATER 4)
    list(GET range 4 end_inclusivity)
  endif()

  ## invalid range end must be reachable from end using the specified increment
  if((${end} LESS ${begin} AND ${increment} GREATER 0) OR (${end} GREATER ${begin} AND ${increment} LESS 0))
    return()
  endif()

  ## set wether the range is reverse or forward
  set(reverse false)
  if(${begin} GREATER ${end})
    set(reverse true)
  endif()

  ## some special cases  -0 = $ (end)
  if(${begin} STREQUAL -0)
    set(begin $)
  endif()
  if(${end} STREQUAL -0)
    set(end $)
  endif()

  ## create math expression to calculate begin and end if anchors are used
  ## negative begin or end is transformed into $-i 
  set(begin_negative false)
  set(end_negative false)
  if(${begin} LESS 0)
    set(begin "($${begin})")
    set(begin_negative true)
  endif()
  if(${end} LESS 0)
    set(end "($${end})")
    set(end_negative true)
  endif()

  ## if begin or end contains a sign operator
  ## put it in parentheses
  if("${begin}" MATCHES "[\\-\\+]")
    set(begin "(${begin})")
  endif()
  if("${end}" MATCHES "[\\-\\+]")
    set(end "(${end})")
  endif()

  ## calculate length of range (number of elements that are spanned)
  ## depending on the orientation of the range 
  if(NOT reverse)
    set(length "${end}-${begin}")
    if(end_inclusivity)
      set(length "${length}+1")
    endif()
    if(NOT begin_inclusivity)
      set(length "${length}-1")
    endif()
  else()
    set(length "${begin}-${end}")
    if(begin_inclusivity)
      set(length "${length}+1")
    endif()
    if(NOT end_inclusivity)
      set(length "${length}-1")
    endif()
  endif()

  ## simplify some typical ranges 
  string(REPLACE "n-n" "0" length "${length}")
  string(REPLACE "n-$" "1" length "${length}")
  string(REPLACE "$-n" "0-1" length "${length}")
  string(REPLACE "$-$" "0" length "${length}")

  ## recalculate length by dividing by step size
  if("${increment}" GREATER 1)
    set(length "(${length}-1)/${increment}+1")
  elseif("${increment}" LESS -1)
    set(length "(${length}-1)/(0-(0${increment}))+1")
  elseif(${increment} EQUAL 0)
    set(length 1)
  endif()

  ## if no anchor is used the length can be directly computed
  if(NOT "${length}" MATCHES "\\$|n" )
    math(EXPR length "${length}")
  else()
     # 
  endif()

  ## set the range string and return it
  set(range "${begin}:${end}:${increment}:${begin_inclusivity}:${end_inclusivity}:${length}:${reverse}")

  return_ref(range)
endfunction()




##
function(range_partial_unpack ref)
    if(NOT ${ref})
      set(${ref} ${ARGN})
    endif()
    set(partial ${${ref}})

    string(REPLACE ":" ";" parts ${partial})
    list(GET parts 0 begin)
    list(GET parts 1 end)
    list(GET parts 2 increment)
    list(GET parts 3 inclusive_begin)
    list(GET parts 4 inclusive_end)
    list(GET parts 5 length)

    set(${ref}.inclusive_begin ${inclusive_begin} PARENT_SCOPE)
    set(${ref}.inclusive_end ${inclusive_end} PARENT_SCOPE)    
    set(${ref}.begin ${begin} PARENT_SCOPE)
    set(${ref}.end ${end} PARENT_SCOPE)
    set(${ref}.increment ${increment} PARENT_SCOPE)
    set(${ref}.length  ${length} PARENT_SCOPE)
endfunction()






## `(<length:<int>> <range...>)-><instanciated range...>`
##
## tries to simplify the specified range for the given length
## his is done by getting the indices and then getting the range from indices
function(range_simplify length)
  set(args ${ARGN})

  list_pop_front(args)
  ans(current_range)

  range_indices("${length}" "${current_range}")
  ans(indices)

  ## get all indices
  while(true)
    list(LENGTH args indices_length)
    if(${indices_length} EQUAL 0)
      break()
    endif()
    list_pop_front(args)
    ans(current_range)
    list_range_get(indices "${current_range}")
    ans(indices)
  endwhile()

  range_from_indices(${indices})
  return_ans()
endfunction()




# returns true if res is a vlaid reference and its type is 'list'
function(list_isvalid  ref )
	is_address("${ref}" )
	ans(isref)
	if(NOT isref)
		return(false)
	endif()
	address_type_get("${ref}")
  ans(type)
	if(NOT "${type}" STREQUAL "list")
		return(false)
	endif()
	return(true)
endfunction()




function(list_new )
	address_new(list ${ARGN})
  return_ans()
endfunction()




function(list_values ref)
	list_isvalid( ${ref})
  ans(islist)
	if(NOT islist)
		return_value()
	endif()
	address_get(${ref} )
  ans(values)
  return_ref(values)
endfunction()




## `(<listA&:<any...> <listB&:<any...>>)-><any..>`
## 
## 
function(set_difference __set_difference_listA __set_difference_listB)
  if("${${__set_difference_listA}}_" STREQUAL "_")
    return()
  endif()

  if(NOT "${${__set_difference_listB}}_" STREQUAL "_")
    list(REMOVE_ITEM "${__set_difference_listA}" ${${__set_difference_listB}})
  endif()
  list(REMOVE_DUPLICATES ${__set_difference_listA})
  #foreach(__list_operation_item ${${__set_difference_listB}})
   # list(REMOVE_ITEM ${__set_difference_listA} ${__list_operation_item})
  #endforeach()
  return_ref(${__set_difference_listA})
endfunction()







# retruns true iff lhs and rhs are the same set (ignoring duplicates)
# the null set is only equal to the null set 
# the order of the set (as implied in being a set) does not matter
function(set_isequal __set_equal_lhs __set_equal_rhs)
  set_issubset(${__set_equal_lhs} ${__set_equal_rhs})
  ans(__set_equal_lhsIsInRhs)
  set_issubset(${__set_equal_rhs} ${__set_equal_lhs})
  ans(__set_equal_rhsIsInLhs)
  if(__set_equal_lhsIsInRhs AND __set_equal_rhsIsInLhs)
    return(true)
  endif() 
  return(false)
endfunction()




# returns true iff lhs is subset of rhs
# duplicate elements in lhs and rhs are ignored
# the null set is subset of every set including itself
# no other set is subset of the null set
# if rhs contains all elements of lhs then lhs is the subset of rhs
function(set_issubset __set_is_subset_of_lhs __set_is_subset_of_rhs)
  list(LENGTH ${__set_is_subset_of_lhs} __set_is_subset_of_length)
  if("${__set_is_subset_of_length}" EQUAL "0")
    return(true)
  endif()
  list(LENGTH ${__set_is_subset_of_rhs} __set_is_subset_of_length)
  if("${__set_is_subset_of_length}" EQUAL "0")
    return(false)
  endif()
  foreach(__set_is_subset_of_item ${${__set_is_subset_of_lhs}})
    list(FIND ${__set_is_subset_of_rhs} "${__set_is_subset_of_item}" __set_is_subset_of_idx)
    if("${__set_is_subset_of_idx}" EQUAL "-1")
      return(false)
    endif()
  endforeach()
  return(true)
endfunction()







# parses a structured list given the structure map
# returning a map which contains all the parsed values
function(structured_list_parse structure_map)
  map_new()
  ans(result)
  set(args ${ARGN})
  obj("${structure_map}")
  ans(structure_map)

  if(NOT structure_map)
    return_ref(result)
  endif() 

  # get all keys
  map_keys(${structure_map} )
  ans(keys)
  set(cutoffs)

  # parse every value descriptor from structure map
  # add every label to the list of cutoffs (a new element definition cuts othe rvalues)
  set(descriptors)
  foreach(key ${keys})
    map_tryget(${structure_map}  "${key}")
    ans(current)
    if(current)
      value_descriptor_parse(${key} ${current})
      ans(current_descriptor)

      list(APPEND descriptors ${current_descriptor})
      map_tryget(${current_descriptor}  "labels")
      ans(labels)
      list(APPEND cutoffs ${labels})        
    endif()
  endforeach()

  # go through each descriptor
  set(errors)
  foreach(current_descriptor ${descriptors})
    nav(labels = current_descriptor.labels)
    nav(id = current_descriptor.id)
    list(REMOVE_ITEM cutoffs ${labels})

    set(error)
    list_parse_descriptor(${current_descriptor} ERROR error UNUSED_ARGS args CUTOFFS cutoffs ${args} )
    #message(FORMAT "args left ${args} after {current_descriptor.id}")
    ans(current_result)
    if(NOT current_result)
      nav(current_result = current_descriptor.default)
    endif()
    if(error)
      list(APPEND errors ${id})
    endif()
    string_decode_semicolon("${current_result}")
    ans(current_result)
    map_navigate_set("result.${id}" ${current_result})
  endforeach()
  #message("args left ${args}")
  map_navigate_set("result.unused" "${args}")
  map_navigate_set("result.errors" "${errors}")
  #message("errors ${errors}")
  return(${result})
endfunction()





  function(list_structure_print_help structure)
    map_keys(${structure} )
    ans(keys)

    set(descriptors)
    set(structure_help)
    foreach(key ${keys})

      map_get(${structure}  ${key})
      ans(descriptor)
      value_descriptor_parse(${key} ${descriptor})
      ans(descriptor)
      list(APPEND descriptors ${descriptor})

      scope_import_map(${descriptor})
      set(current_help)
      list(GET labels 0 first_label)
      set(current_help ${first_label})

      if(NOT "${default}_" STREQUAL "_")
        set(current_help "[${current_help} = ${default}]")
      elseif(${min} EQUAL 0 )
        set(current_help "[${current_help}]")
      endif()


      set(structure_help "${structure_help} ${current_help}")

    endforeach()
    if(structure_help)
      string(SUBSTRING "${structure_help}" 1 -1 structure_help)
    endif()
    message("${structure_help}")
    message("Details: ")
    foreach(descriptor ${descriptors})
      scope_import_map(${descriptor})
      list_to_string( labels ", ")
      ans(res)
      message("${displayName}: ${res}")
      if(description)
        message_indent_push()
        message("${description}")
        message_indent_pop()
      endif()

    endforeach()
  endfunction()






function(config_function config_obj config_definition key)
    set(args ${ARGN})

  if("${key}"  STREQUAL "*")
    return(${config_obj})
  endif()
  if("${key}" STREQUAL "help")
    list_structure_print_help(${config_definition})
    return()
  endif()
  if("${key}" STREQUAL "print" )
    json_print(${config_obj})
    return()
  endif()
  if("${key}" STREQUAL "set")
    list_pop_front(args)
    ans(key)
    map_set("${config_obj}" "${key}" ${args})
  endif()
  map_get("${config_obj}" "${key}")
  return_ans()
endfunction()






function(config_setup name definition)
  map_get(global unused_command_line_args)
  ans(args)
  structured_list_parse("${definition}" ${args})
  ans(config)
  map_tryget(${config} unused)
  ans(args)
  map_set(global unused_command_line_args ${args})
  #curry(config_function("${config}" "${definition}" /1) as "${name}")
  curry3("${name}"(a) => config_function("${config}" "${definition}" /a))
endfunction()




function(beep)
  string(ASCII 7 beep)
  echo_append("${beep}")
endfunction()




function(cached arg)
    json("${arg}")
    ans(ser)
    string(MD5 cache_key "${ser}")
    set(args ${ARGN})
    list(LENGTH args arg_len)
    if(arg_len)

      map_set(global_cache_entries "${cache_key}" "${args}")
      return_ref(args)
    endif()


    map_tryget(global_cache_entries "${cache_key}")    
    ans(res)
    return_ref(res)


endfunction()

  macro(return_hit arg_name)
    cached("${${arg_name}}")
    if(__ans)
      message("hit")
      return_ans()
    endif()
      message("not hit")
  endmacro()








## convenience function for accessing cmake
function(cmake)
  wrap_executable(cmake "${CMAKE_COMMAND}")
  cmake(${ARGN})
  return_ans()
endfunction() 






## fast wrapper for cmake
function(cmake_lean)
  wrap_executable_bare(cmake_lean "${CMAKE_COMMAND}")
  cmake_lean(${ARGN})
  return_ans()
endfunction()




## returns the entry script file from which cmake was started
function(cmake_entry_point)
  commandline_args_get()
  ans(args)
  list_extract_labelled_value(args -P)
  ans(script_file)
  path_qualify(script_file)
  return_ref(script_file)
endfunction()




## commandline_args_get([--no-script])-> <string...>
## 
## returns the command line arguments with which cmake 
## was without the executable
##
## --no-script flag removes the script file from the command line args
##
## Example:
## command line: 'cmake -P myscript.cmake a s d'
## commandline_args_get() -> -P;myscript;a;s;d
## commandline_args_get(--no-script) -> a;s;d

function(commandline_args_get)
  set(args ${ARGN})
  list_extract_flag(args --no-script)
  ans(no_script)
  commandline_get()
  ans(args)
  # remove executable
  list_pop_front(args)
  if(no_script)
    list_extract_labelled_value(args -P)
  endif()
  return_ref(args)
endfunction()




# returns the list of command line arguments
function(commandline_arg_string)
  set(args)
  foreach(i RANGE 3 ${CMAKE_ARGC})  
    set(current ${CMAKE_ARGV${i}})
    string(REPLACE \\ / current "${current}")
    set(args "${args} ${current}")
    
  endforeach()  

  return_ref(args)
endfunction() 






# extracts the specified values from the command line (see list extract)
# returns the rest of the command line
# the first three arguments of commandline_get are cmake command, -P, script file 
# these are ignored
function(commandline_extract)
  commandline_get()
  ans(args)
  list_extract(args cmd p script ${ARGN})
  ans(res)
  vars_elevate(${ARGN})
  set(res ${cmd} ${p} ${script} ${res})
  return_ref(res)
endfunction()






# returns the list of command line arguments
function(commandline_get)
  set(args)
  foreach(i RANGE ${CMAKE_ARGC})  
    set(current ${CMAKE_ARGV${i}})
    string(REPLACE \\ / current "${current}")
    list(APPEND args "${current}")    
  endforeach()  

  return_ref(args)
endfunction() 


## 
##
## returns script | configure | build
function(cmake_mode)

endfunction()





# returns the list of command line arguments
function(commandline_string)
  set(args)
  foreach(i RANGE ${CMAKE_ARGC})  
    set(current ${CMAKE_ARGV${i}})
    string(REPLACE \\ / current "${current}")
    set(args "${args} ${current}")
    
  endforeach()  

  return_ref(args)
endfunction() 





function(dbg)
  set(args ${ARGN})
  list_extract_flag(args --indented)
  ans(indented)
  if(NOT args)
    set(last_return_value "${__ans}")
    set(args last_return_value)
  endif()
  if("${args}")
    is_map("${${args}}")
    ans(ismap)
    if(ismap)
      if(indented)
        json_indented("${${args}}")
      else()
        json("${${args}}")
      endif()
      ans("${args}")
    endif()
    dbg("${args}: '${${args}}'")
    return()
  endif()
  list_length(args)
  ans(len)
  if("${len}" EQUAL 1)
    is_map("${args}")
    ans(ismap)
    if(ismap)  
      if(indented)
        json_indented("${args}")
      else()
        json("${args}")
      endif()
      ans("${args}")

    endif()
    message(FORMAT "dbg (${__function_call_func}): '${args}'")
    return()
  endif()

  foreach(arg ${args})
    dbg("${arg}")
  endforeach()

  return()
endfunction()




# converts a decimal number to a hexadecimal string
# e.g. dec2hex(195936478) => "BADC0DE"

  function(dec2hex n)
    set(rest ${n})
    set(converted)

    if("${n}" EQUAL 0)
      return(0)
    endif()
    
    while(${rest} GREATER 0)
      math(EXPR c "${rest} % 16")
      math(EXPR rest "(${rest} - ${c})>> 4")

      if("${c}" LESS 10)
        list(APPEND converted "${c}")
      else()
        if(${c} EQUAL 10)
          list(APPEND converted A)
        elseif(${c} EQUAL 11)
          list(APPEND converted B)
        elseif(${c} EQUAL 12)
          list(APPEND converted C)
        elseif(${c} EQUAL 13)
          list(APPEND converted D)
        elseif(${c} EQUAL 14)
          list(APPEND converted E)
        elseif(${c} EQUAL 15)
          list(APPEND converted F)
        endif()
      endif()
    endwhile()
    list(LENGTH converted len)
    if(${len} LESS 2)
      return(${converted})
    endif()
    list(REVERSE converted)
    string_combine("" ${converted})
    return_ans()
  endfunction() 




## `()->`
## 
## defines a function called alias which caches its results
##
function(define_cache_function generate_value)
  set(args ${ARGN})

  list_extract_labelled_value(args =>)
  ans(alias)
  if(NOT alias)
    function_new()
    ans(alias)
  endif()

  list_extract_labelled_value(args --generate-key)
  ans(generate_key)
  if(NOT generate_key)
      set(generate_key "[]()checksum_string('{{ARGN}}')")
  endif()

  list_extract_labelled_value(args --select-value)
  ans(select_value)
  if(NOT select_value)
      set(select_value "[]()set_ans('{{ARGN}}')")
  endif()
  

  list_extract_labelled_value(args --cache-dir)
  ans(cache_dir)
  if(NOT cache_dir)
    cmakepp_config(cache_dir)
    ans(cache_dir)
    set(cache_dir "${cache_dir}/cache_functions/${alias}")
  endif()


  list_extract_flag(args --refresh)
  ans(refresh)

#    print_vars(generate_key generate_value select_value refresh  cache_dir)
  if(refresh)
    rm(-r "${cache_dir}")
  endif()
    
  callable_function("${generate_key}")
  ans(generate_key)
  callable_function("${generate_value}")
  ans(generate_value)
  callable_function("${select_value}")
  ans(select_value)

  eval("
    function(${alias})
      set(args \${ARGN})
      list_extract_flag(args --update-cache)
      ans(update)

      ${generate_key}(\${args})
      ans(cache_key)
      set(cache_path \"${cache_dir}/\${cache_key}\")
      
      map_has(memory_cache \"\${cache_path}\")
      ans(has_entry)

      if(has_entry AND NOT update)
  #      message(memhit)
        map_tryget(memory_cache \"\${cache_path}\")
        ans(cached_result)
      elseif(EXISTS \"\${cache_path}/value.scmake\" AND NOT update)
   #     message(filehit)
        cmake_read(\"\${cache_path}/value.scmake\")
        ans(cached_result)
        map_set(memory_cache \"\${cache_path}\" \${cached_result})
      else()
       # if(update)
    #      message(update )
       # else()
     #     message(miss )
      #  endif()
        ${generate_value}(\${args})
        ans(cached_result)
        map_set(memory_cache \"\${cache_path}\" \${cached_result})
        cmake_write(\"\${cache_path}/value.scmake\" \${cached_result})
      endif()
      ${select_value}(\${cached_result})
      return_ans()
    endfunction()
    ")
  return_ref(alias)
endfunction()








  function(echo_append_indent)
    message_indent_get()
    ans(indent)

    echo_append("${indent} ${ARGN}")
    return()
  endfunction()





  function(echo_append_padded len str)
    string_pad("${str}" "${len}" " ")
    ans(str)
    echo_append("${str}")
  endfunction()




# Evaluate expression (faster version)
# Suggestion from the Wiki: http://cmake.org/Wiki/CMake/Language_Syntax
# Unfortunately, no built-in stuff for this: http://public.kitware.com/Bug/view.php?id=4034
# eval will not modify ans (the code evaluated may modify ans)
# vars starting with __eval should not be used in code
function(eval __eval_code)
  
  # one file per execution of cmake (if this file were in memory it would probably be faster...)
  fwrite_temp("" ".cmake")
  ans(__eval_temp_file)


# speedup: statically write filename so eval boils down to 2 function calls
# no need to keep __ans
 file(WRITE "${__eval_temp_file}" "
function(eval __eval_code)
  file(WRITE \"${__eval_temp_file}\" \"\${__eval_code}\")
  include(\"${__eval_temp_file}\")
  set(__ans \${__ans} PARENT_SCOPE)
  #return_ans()
endfunction()
  ")
include("${__eval_temp_file}")


eval("${__eval_code}")
return_ans()
endfunction()







# evaluates a cmake math expression and returns its
# value
function(eval_math)
  math(EXPR res ${ARGN})
  return_ref(res)
endfunction()





# macro version of eval function which causes set(PARENT_SCOPE ) statements to access 
# scope of invokation
macro(eval_ref __eval_ref_theref)
  ans(__eval_ref_current_ans)
  cmakepp_config(temp_dir)
  ans(__eval_ref_dir)

  fwrite_temp("${${__eval_ref_theref}}" ".cmake")
  ans(__eval_ref_filename)

  set_ans("${__eval_ref_current_ans}")
#_message("${ref_count}\n${${__eval_ref_theref}}")

  include(${__eval_ref_filename})
  ans(__eval_ref_res)
  
  cmakepp_config(keep_temp)
  ans(__eval_ref_keep_temp)
  if(NOT __eval_ref_keep_temp)
    file(REMOVE ${__eval_ref_filename})
  endif()


  set_ans("${__eval_ref_res}")
endmacro()





# evaluates a truth expression 'if' and returns true or false 
function(eval_truth)
  if(${ARGN})
    return(true)
  endif()
  return(false)
endfunction()




function(global_config key)
  map_get(global "${key}")
  ans(res)
  set("${key}" "${res}" PARENT_SCOPE)
  return_ref(res)
endfunction()




  function(graphsearch)
    cmake_parse_arguments("" "" "EXPAND;PUSH;POP" "" ${ARGN})

    if(NOT _EXPAND)
      message(FATAL_ERROR "graphsearch: no expand function set")
    endif()

    function_import("${_EXPAND}" as gs_expand REDEFINE)
    function_import("${_PUSH}" as gs_push REDEFINE)
    function_import("${_POP}" as gs_pop REDEFINE)

    # add all arguments to stack
    foreach(node ${_UNPARSED_ARGUMENTS})

      gs_push(${node})
    endforeach()

    # iterate
    while(true)
      gs_pop()
      ans(current)
      #message("current ${current}")
      # recursion anchor - no more node
      if(NOT current)
        break()
      endif()
      gs_expand(${current})
      ans(successors)
      foreach(successor ${successors})
        gs_push(${successor})
      endforeach()
      
    endwhile()
  endfunction()






function(hex2dec str)

  string(LENGTH "${str}" len)
  if("${len}" LESS 1)
  elseif("${len}" EQUAL 1)
    if("${str}" MATCHES "[0-9]")
      return("${str}")
    elseif( "${str}" MATCHES "[aA]")
      return(10)
    elseif( "${str}" MATCHES "[bB]")
      return(11)
    elseif( "${str}" MATCHES "[cC]")
      return(12)
    elseif( "${str}" MATCHES "[dD]")
      return(13)
    elseif( "${str}" MATCHES "[eE]")
      return(14)
    elseif( "${str}" MATCHES "[fF]")
      return(15)
    else()
      # invalid character
      return()
    endif()
  else()
    math(EXPR len "${len} - 1")
    set(result 0)
    foreach(i RANGE 0 ${len})
      string_char_at("${i}" "${str}")
      ans(c)
      

      hex2dec("${c}")
      ans(c)
      if("${c}_" STREQUAL "_")
        
        # illegal char
        return()
      endif()
      
      math(EXPR result "${result} + (2 << ((${len}-${i})*4)) * ${c}")
    endforeach()
    math(EXPR result "${result} >> 1")
    return(${result})
  endif()
  return()
endfunction()




# spawns an interactive cmake session
# use @echo off and @echo on to turn printing of result off and on
# use quit or exit to terminate
# usage: cmake()
function(icmake)
  # outer loop loops untul quit or exit is input
  set(echo on)
  set(strict off)
  while(true)
    pwd()
    ans(pwd)
    echo_append("icmake ${pwd}/> ")
    set(cmd)
    # inner loop for reading multiline inputs (delimited by \)
    set(line "\\")
    set(first true)
    while("${line}" MATCHES ".*\\\\$")
      if(first)
        set(first false)
        set(line "")
      else()
        echo_append("        ")
      endif()

      read_line()
      ans(line)
      if("${line}" MATCHES ".*\\\\$")
        string_slice("${line}" 0 -2)
        ans(theline)
      else()
        set(theline "${line}")
      endif()
      set(cmd "${cmd}\n${theline}")

    endwhile()
    if("${line}" MATCHES "^(quit|exit)$")
      break()
    endif()

    if("${cmd}" MATCHES "@echo on")
      message("echo is now on")
      set(echo on)
      break()
    elseif("${cmd}" MATCHES "@echo off")
      message("echo is now off")
      set(echo off)
      break()
    elseif("${cmd}" MATCHES "@string off")
      message("strict is now off")
      set(strict off)
    elseif("${cmd}" MATCHES "@string on")
      message("strict is no on")
      set(strict on)
    else()
      # check if cmd is valid cmake
        #todo
      if(NOT strict)
        lazy_cmake("${cmd}")
        ans(cmd)
      endif()
      set_ans("${ANS}")
      eval_ref(cmd)
      ans(ANS)
      if(echo)
        json_print(${ANS})
      endif()
    endif()
  endwhile()
  return()
endfunction()





## 
##
## returns an identifier of the form `__{ARGN}_{unique}`
## the idetnfier will not be a defined function 
## nor a defined variable, nor a existing global 
## property.  it is unique to the execution of cmake
## and can be used as a function name
function(identifier)
  #string_codes()
  while(true)
    make_guid()
    ans(guid)
    set(identifier "__${ARGN}_${guid}")
    if(NOT COMMAND "${identifier}" AND NOT "${identifier}")
      return_ref(identifier)
    endif()
  endwhile()
  message(FATAL_ERROR "code never reached")
endfunction()




## includes all files identified by globbing expressions
## see `glob` on globbing expressions
function(include_glob)
  set(args ${ARGN})
  glob(${args})
  ans(files)
  foreach(file ${files})
    include_once("${file}")
  endforeach()

  return()
endfunction()





#include guard returns if the file was already included 
# usage :  at top of file write include_guard(${CMAKE_CURRENT_LIST_FILE})
macro(include_guard __include_guard_file)
  #string(MAKE_C_IDENTIFIER "${__include_guard_file}" __include_guard_file)
  get_property(is_included GLOBAL PROPERTY "ig_${__include_guard_file}")
  if(is_included)
    _return()
  endif()
  set_property(GLOBAL PROPERTY "ig_${__include_guard_file}" true)
endmacro()




function(include_once file)
  get_filename_component(file "${file}" REALPATH)
  string(MD5 md5 "${file}")
  get_property(wasIncluded GLOBAL PROPERTY "include_guards.${md5}")
  if(wasIncluded)
  	return()
  endif()
  set_property(GLOBAL PROPERTY "include_guards.${md5}" true)
  include("${file}")
endfunction()




## returns true iff cmake is currently in script mode
function(is_script_mode)
 commandline_get()
 ans(args)

 list_extract(args command P path)
 if("${P}" STREQUAL "-P")
  return(true)
else()
  return(false)
 endif()
endfunction()

## returns the file that was executed via script mode
function(script_mode_file)
  commandline_get()
  ans(args)

 list_extract(args command P path)
if(NOT "${P}" STREQUAL "-P")
  return()
endif()
  path("${path}")
  ans(path)
  return_ref(path)
endfunction()






# turns the lazy cmake code into valid cmake
#
function(lazy_cmake cmake_code)
# normalize cmake 
  # 
  string(STRIP "${cmake_code}" cmake_code )
  if(NOT "${cmake_code}" MATCHES "[ ]*[a-zA-Z0-9_]+\\(.*\\)[ ]*")
    string(REGEX REPLACE "[ ]*([a-zA-Z0-9_]+)[ ]*(.*)" "\\1(\\2)" cmd "${cmake_code}")
    string(REGEX REPLACE "[ ]*([a-zA-Z0-9_]+)[ ]*(.*)" "\\1" cmdname "${cmake_code}")
    if(NOT COMMAND "${cmdname}")
      string(STRIP "${cmake_code}" cc)
      set(cmd "set_ans(\"\${${cc}}\")")
    endif()
  endif()



  return_ref(cmd)

endfunction()





#creates a unique id
function(make_guid)
  string(RANDOM LENGTH 10 id)
   return_ref(id)
endfunction()

## faster
macro(make_guid)
  string(RANDOM LENGTH 10 __ans)
  #set(__ans ${id} PARENT_SCOPE)
endmacro()





# retruns the larger of the two values
function(math_max a b)
  if(${a} GREATER ${b})
    return(${a})
  else()
    return(${b})
  endif() 
endfunction()





function(math_min a b)
  if(${a} LESS ${b})
    return(${a})
  else()
    return(${b})
  endif() 
endfunction()





function(message)
	cmake_parse_arguments("" "PUSH_AFTER;POP_AFTER;DEBUG;INFO;FORMAT;PUSH;POP" "LEVEL" "" ${ARGN})
	set(log_level ${_LEVEL})
	set(text ${_UNPARSED_ARGUMENTS})

	## indentation
	if(_PUSH)
		message_indent_push()
	endif()
	if(_POP)
		message_indent_pop()
	endif()


	message_indent_get()
	ans(indent)
	if(_POP_AFTER)
		message_indent_pop()
	endif()
	if(_PUSH_AFTER)
		message_indent_push()
	endif()
	## end of indentationb


	## log_level
	if(_DEBUG)
		if(NOT log_level)
			set(log_level 3)
		endif()
		set(text STATUS ${text})
	endif()
	if(_INFO)
		if(NOT log_level)
			set(log_level 2)
		endif()
		set(text STATUS ${text})
	endif()
	if(NOT log_level)
		set(log_level 0)
	endif()

	if(NOT MESSAGE_LEVEL)
		set(MESSAGE_LEVEL 3)
	endif()

	list(GET text 0 modifier)
	if(${modifier} MATCHES "FATAL_ERROR|STATUS|AUTHOR_WARNING|WARNING|SEND_ERROR|DEPRECATION")
		list(REMOVE_AT text 0)
	else()
		set(modifier)
	endif()

	## format
	if(_FORMAT)
		map_format( "${text}")
		ans(text)
	endif()

	if(NOT MESSAGE_DEPTH )
		set(MESSAGE_DEPTH -1)
	endif()

	if(NOT text)
		return()
	endif()

	map_new()
	ans(message)
	map_set(${message} text "${text}")
	map_set(${message} indent_level ${message_indent_level})
	map_set(${message} log_level ${log_level})
	map_set(${message} mode "${modifier}")
	event_emit(on_message ${message})

	if(log_level GREATER MESSAGE_LEVEL)
		return()
	endif()
	if(MESSAGE_QUIET)
		return()
	endif()
	# check if deep message are to be ignored
	if(NOT MESSAGE_DEPTH LESS 0)
		if("${message_indent_level}" GREATER "${MESSAGE_DEPTH}")
			return()
		endif()
	endif()

	tock()

	## clear status line
	status_line_clear()
	_message(${modifier} "${indent}" "${text}")
	status_line_restore()

	
	return()
endfunction()








  
  function(message_indent msg) 
    message_indent_get()
    ans(indent)
    _message("${indent}${msg}")
  endfunction()






function(message_indent_get)
  message_indent_level()
  ans(level)
  string_repeat(" " ${level})
  return_ans()
endfunction()





function(message_indent_level)
  map_peek_back("global" "message_indent_level")
  ans(level)
  if(NOT level)
    return(0)
  endif()
  return_ref(level)
endfunction()






function(message_indent_pop)
  map_pop_back(global message_indent_level)
  ans(old_level)
  message_indent_level()
  ans(current_level)
  return_ref(current_level)
endfunction()







function(message_indent_push)
  
  set(new_level ${ARGN})
  if("${new_level}_" STREQUAL "_")
    set(new_level +1)
  endif()
  
  if("${new_level}" MATCHES "[+\\-]")
    message_indent_level()
    ans(previous_level)
    math(EXPR new_level "${previous_level} ${new_level}")
    if(new_level LESS 0)
      set(new_level 0)
    endif()
  endif()
  map_push_back(global message_indent_level ${new_level})
  return(${new_level})
endfunction()




# returns the identifier for the os being used
function(os)
  if(WIN32)
    return(Windows)
  elseif(UNIX)
    return(Linux)
  else()
    return()
  endif()


endfunction()





# parses the command line string into parts (handling strings and semicolons)
function(parse_command_line result args)

  string(ASCII  31 ar)
  string(REPLACE "\;" "${ar}" args "${args}" )
  string(REGEX MATCHALL "((\\\"[^\\\"]*\\\")|[^ ]+)" matches "${args}")
  string(REGEX REPLACE "(^\\\")|(\\\"$)" "" matches "${matches}")
  string(REGEX REPLACE "(;\\\")|(\\\";)" ";" matches "${matches}")
# hack for windows paths
  string(REPLACE "\\" "/" matches "${matches}")
  set("${result}" "${matches}" PARENT_SCOPE)
endfunction()




function(pkg)
  cmakepp_project_cli(${ARGN})
  return_ans()
endfunction()


  




## prints str to console without reformatting it and no message type
function(print str)
  _message("${str}")
endfunction()




## takes a <command line~> or <process start info~>
## and returns a valid  process start info
function(process_start_info)
  set(__args ${ARGN})

  list_extract_labelled_value(__args TIMEOUT)
  ans(timeout_arg)

  list_extract_labelled_value(__args WORKING_DIRECTORY)
  ans(cwd_arg)

  if("${ARGN}_" STREQUAL "_")
    return()
  endif()


  obj("${ARGN}")
  ans(obj)

  if(NOT obj)
    command_line(${__args})
    ans(obj)
  endif()


  if(NOT obj)
    message(FATAL_ERROR "invalid process start info ${ARGN}")
  endif()

  set(path)
  set(cwd)
  set(command)
  set(args)
  set(parameters)
  set(timeout)
  set(arg_string)
  set(command_string)

  scope_import_map(${obj})

  if("${args}_" STREQUAL "_")
    set(args ${parameters})
  endif()

  if("${command}_" STREQUAL "_")
    set(command "${path}")
    if("${command}_" STREQUAL "_")
      message(FATAL_ERROR "invalid <process start info> missing command property")
    endif()
  endif()

  if(timeout_arg)
    set(timeout "${timeout_arg}")
  endif()

  if("${timeout}_" STREQUAL "_" )
    set(timeout -1)
  endif()




  if(cwd_arg)
    set(cwd "${cwd_arg}")
  endif()

  path("${cwd}")
  ans(cwd)

  if(EXISTS "${cwd}")
    if(NOT IS_DIRECTORY "${cwd}")
      message(FATAL_ERROR "specified working directory path is a file not a directory: '${cwd}'")
    endif()
  else()
    message(FATAL_ERROR "specified workind directory path does not exist : '${cwd}'")
  endif()



  # create a map from the normalized input vars
  map_capture_new(command args cwd timeout)
  return_ans()

endfunction()




macro(promote var_name)
  set(${var_name} ${${var_name}} PARENT_SCOPE)
endmacro()  





macro(promote_if_exists var_name)
  if(DEFINED ${var_name})
    promote(${var_name})
  endif()
endmacro()




function(require file)
  file(GLOB_RECURSE res "${file}")

  if(NOT res)
    message(FATAL_ERROR "could not find required file for '${file}'")
  endif()

  foreach(file ${res})
    include("${file}")
  endforeach()

endfunction()






  function(require_include_dirs )
    require_map()
    ans(map)
    map_get(${map}  include_dirs)
    ans(stack)
    stack_pop(${stack})
    ans(dirs)
    list(APPEND dirs ${ARGN})
    stack_push(${stack} ${dirs})

  endfunction()





function(require_map)
  map_set_hidden(:__require_map __type__ map)
  stack_new()
  ans(stack)
  map_set_hidden(:__require_map include_dirs ${stack})

  function(require_map)
    return(":__require_map")
  endfunction()
  require_map()
  return_ans()
endfunction()




# assigns the result return by a functi on to the specified variable
# must be immediately called after funct ion call
# if no argument is passed current __ans will be cleared (this should be called at beginning of ffunc)
# the name ans stems from calculators ans and signifies the last answer
function(ans __ans_result)
  set(${__ans_result} "${__ans}" PARENT_SCOPE)
endfunction()







## appends the last return value to the specified list
macro(ans_append __lst)
  list(APPEND ${__lst} ${__ans})
endmacro()




## extracts the the specified variables in order from last result
## returns the rest of the result which was unused
## ```
## do_something()
## ans_extract(value1 value2)
## ans(rest)
## ``` 
macro(ans_extract)
  ans(__ans_extract_list)
  list_extract(__ans_extract_list ${ARGN})
endmacro()




# used to clear the __ans variable. may also called inside a function with argument PARENT_SCOPE to clear
# parent __ans variable
macro(clr)
  set(__ans ${ARGN})
endmacro()




## 
##
## when not to use: if your data degrades when evaluated by a macro
## for example escapes are resolved
macro(return)
  set(__ans "${ARGN}" PARENT_SCOPE)
	_return()
endmacro()




#returns the last returned value
# this is a shorthand useful when returning the rsult of a previous function
macro(return_ans)
  return_ref(__ans)
endmacro()






  macro(return_math expr)
    math(EXPR __return_math_res "${expr}")
    return(${__return_math_res})
  endmacro()





# returns the var called ${ref}
# this inderection is needed when returning escaped string, else macro will evaluate the string
macro(return_ref __return_ref_ref)
  set(__ans "${${__return_ref_ref}}" PARENT_SCOPE)
  _return()
endmacro()




macro(return_reset)
  set(__ans PARENT_SCOPE)
endmacro()




macro(return_truth)
  if(${ARGN})
    return(true)
  endif()
  return(false)
endmacro()





function(set_ans )
  set(__set_ans_val ${ARGN})
  return_ref(__set_ans_val)
endfunction()




function(set_ans_ref __set_ans_ref_ref)
  return_ref("${__set_ans_ref_ref}")

endfunction()





  macro(return_data data)
    data("${data}")
    return_ans()
  endmacro()




macro( return_if_run_before id)
	#string(MAKE_C_IDENTIFIER ${id} guard)
	string_normalize( "{id}")
  ans(guard)
	get_property(was_run GLOBAL PROPERTY ${guard})
	if(was_run)
		return()
	endif()
	set_property(GLOBAL PROPERTY ${guard} true)
endmacro()






  macro(return_nav)
    assign(result = ${ARGN})
    return_ref(result)
  endmacro()





#returns a value 
# expects a variable called result to exist in function signature
# may only be used inside functions
macro(return_value)
  if(NOT result)
    message(FATAL_ERROR "expected a variable called result to exist in function")
    return()
  endif()
  set(${result} ${ARGN} PARENT_SCOPE)
  return(${ARGN})
endmacro()




function(scope_resolve key)
  map_has("${local}" "${key}")
  ans(has_local)
  if(has_local)
    map_tryget("${local}" "${key}")
    return_ans()
  endif()

  obj_get("${this}" "${key}")
  return_ans()
endfunction()   




# sleeps for the specified amount of seconds
function(sleep seconds)
  if("${CMAKE_MAJOR_VERSION}" LESS 3)
    if(UNIX)
      execute_process(COMMAND sleep ${seconds} RESULT_VARIABLE res)

      if(NOT "${res}" EQUAL 0)
        message(FATAL_ERROR "sleep failed")
      endif()
      return()
    endif()

    message(WARNING "sleep no available in cmake version ${CMAKE_VERSION}")
    return()
  endif()

  cmake_lean(-E sleep "${seconds}")
  return()
endfunction()





  function(spinner)
    map_set(__spinner counter 0)
    function(spinner)
      set(spinner "|" "/" "-")
      list(APPEND spinner "\\")
      map_tryget(__spinner counter)
      ans(counter)
      math(EXPR next "(${counter} + 1) % 4")
      map_set(__spinner counter ${next})
      list(GET spinner ${counter} res )
      return_ref(res)
    endfunction()
  endfunction()




function(status_line)
  map_set(global status "${ARGN}")
  string_pad("${ARGN}" 100)
  ans(str)  
  echo_append("\r${str}\r")
endfunction()  




function(status_line_clear)

  string_repeat(" " 100)
  ans(whitespace)

  eval("

    function(status_line_clear)
      map_tryget(global status)
      ans(status)
      if(\"\${status}_\" STREQUAL \"_\")
        return()
      endif()

      echo_append(\"\r${whitespace}\r\")
    endfunction()
  ")
  status_line_clear()
endfunction()






function(status_line_restore)
  map_tryget(global status)
  ans(status)
  if("${status}_" STREQUAL "_")
    return()
  endif()
  echo_append("${status}")
endfunction()




 function(expr_string_parse str)
  set(regex_single_quote_string "'[^']*'")
  set(regex_double_quote_string "\"[^\"]*\"")
  if("${str}" MATCHES "^${regex_single_quote_string}$")
    string_slice("${str}" 1 -2)
    return_ans()
  endif()
  if("${str}" MATCHES "^(${regex_double_quote_string})$")
    string_slice("${str}" 1 -2)
    return_ans()
  endif()
  return()
endfunction()




## this function creates a string containing status information
  function(progress_string value maximum ticks)
    math(EXPR multiplier "20/${maximum}")
    math(EXPR value "${value} * ${multiplier}")
    math(EXPR maximum "${maximum} * ${multiplier}")
    math(EXPR rest_count "${maximum} - ${value}")
    string_repeat("=" ${value})
    ans(status)
    string_repeat(" " ${rest_count})
    ans(rest)
    math(EXPR status_ticker "${ticks} % 5")
    string_repeat("." ${status_ticker})
    ans(status_ticker)
    return("[${status}${rest}]${status_ticker}          ")
  endfunction()




# returns a map of all set target properties for target
# if target does not exist it returns null
function(target_get_properties target)

  if(NOT TARGET "${target}")
    return()
  endif()
  set(props
    DEBUG_OUTPUT_NAME
    DEBUG_POSTFIX
    RELEASE_OUTPUT_NAME
    RELEASE_POSTFIX
    ARCHIVE_OUTPUT_DIRECTORY
    ARCHIVE_OUTPUT_DIRECTORY_DEBUG
    ARCHIVE_OUTPUT_DIRECTORY_RELEASE
    ARCHIVE_OUTPUT_NAME
    ARCHIVE_OUTPUT_NAME_DEBUG
    ARCHIVE_OUTPUT_NAME_RELEASE
    AUTOMOC
    AUTOMOC_MOC_OPTIONS
    BUILD_WITH_INSTALL_RPATH
    BUNDLE
    BUNDLE_EXTENSION
    COMPILE_DEFINITIONS
    COMPILE_DEFINITIONS_DEBUG
    COMPILE_DEFINITIONS_RELEASE
    COMPILE_FLAGS
    DEBUG_POSTFIX
    RELEASE_POSTFIX
    DEFINE_SYMBOL
    ENABLE_EXPORTS
    EXCLUDE_FROM_ALL
    EchoString
    FOLDER
    FRAMEWORK
    Fortran_FORMAT
    Fortran_MODULE_DIRECTORY
    GENERATOR_FILE_NAME
    GNUtoMS
    HAS_CXX
    IMPLICIT_DEPENDS_INCLUDE_TRANSFORM
    IMPORTED
    IMPORTED_CONFIGURATIONS
    IMPORTED_IMPLIB
    IMPORTED_IMPLIB_DEBUG
    IMPORTED_IMPLIB_RELEASE
    IMPORTED_LINK_DEPENDENT_LIBRARIES
    IMPORTED_LINK_DEPENDENT_LIBRARIES_DEBUG
    IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE
    IMPORTED_LINK_INTERFACE_LANGUAGES
    IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG
    IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE
    IMPORTED_LINK_INTERFACE_LIBRARIES
    IMPORTED_LINK_INTERFACE_LIBRARIES_DEBUG
    IMPORTED_LINK_INTERFACE_LIBRARIES_RELEASE
    IMPORTED_LINK_INTERFACE_MULTIPLICITY
    IMPORTED_LINK_INTERFACE_MULTIPLICITY_DEBUG
    IMPORTED_LINK_INTERFACE_MULTIPLICITY_RELEASE
    IMPORTED_LOCATION
    IMPORTED_LOCATION_DEBUG
    IMPORTED_LOCATION_RELEASE
    IMPORTED_NO_SONAME
    IMPORTED_NO_SONAME_DEBUG
    IMPORTED_NO_SONAME_RELEASE
    IMPORTED_SONAME
    IMPORTED_SONAME_DEBUG
    IMPORTED_SONAME_RELEASE
    IMPORT_PREFIX
    IMPORT_SUFFIX
    INCLUDE_DIRECTORIES
    INTERFACE_INCLUDE_DIRECTORIES
    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
    INSTALL_NAME_DIR
    INSTALL_RPATH
    INSTALL_RPATH_USE_LINK_PATH
    INTERPROCEDURAL_OPTIMIZATION
    INTERPROCEDURAL_OPTIMIZATION_DEBUG
    INTERPROCEDURAL_OPTIMIZATION_RELEASE
    LABELS
    LIBRARY_OUTPUT_DIRECTORY
    LIBRARY_OUTPUT_DIRECTORY_DEBUG
    LIBRARY_OUTPUT_DIRECTORY_RELEASE
    LIBRARY_OUTPUT_NAME
    LIBRARY_OUTPUT_NAME_DEBUG
    LIBRARY_OUTPUT_NAME_RELEASE
    LINKER_LANGUAGE
    LINK_DEPENDS
    LINK_FLAGS
    LINK_FLAGS_DEBUG
    LINK_FLAGS_RELEASE
    LINK_INTERFACE_LIBRARIES
    LINK_INTERFACE_LIBRARIES_DEBUG
    LINK_INTERFACE_LIBRARIES_RELEASE
    LINK_INTERFACE_MULTIPLICITY
    LINK_INTERFACE_MULTIPLICITY_DEBUG
    LINK_INTERFACE_MULTIPLICITY_RELEASE
    LINK_SEARCH_END_STATIC
    LINK_SEARCH_START_STATIC
    #LOCATION
    #LOCATION_DEBUG
    #LOCATION_RELEASE
    MACOSX_BUNDLE
    MACOSX_BUNDLE_INFO_PLIST
    MACOSX_FRAMEWORK_INFO_PLIST
    MAP_IMPORTED_CONFIG_DEBUG
    MAP_IMPORTED_CONFIG_RELEASE
    OSX_ARCHITECTURES
    OSX_ARCHITECTURES_DEBUG
    OSX_ARCHITECTURES_RELEASE
    OUTPUT_NAME
    OUTPUT_NAME_DEBUG
    OUTPUT_NAME_RELEASE
    POST_INSTALL_SCRIPT
    PREFIX
    PRE_INSTALL_SCRIPT
    PRIVATE_HEADER
    PROJECT_LABEL
    PUBLIC_HEADER
    RESOURCE
    RULE_LAUNCH_COMPILE
    RULE_LAUNCH_CUSTOM
    RULE_LAUNCH_LINK
    RUNTIME_OUTPUT_DIRECTORY
    RUNTIME_OUTPUT_DIRECTORY_DEBUG
    RUNTIME_OUTPUT_DIRECTORY_RELEASE
    RUNTIME_OUTPUT_NAME
    RUNTIME_OUTPUT_NAME_DEBUG
    RUNTIME_OUTPUT_NAME_RELEASE
    SKIP_BUILD_RPATH
    SOURCES
    SOVERSION
    STATIC_LIBRARY_FLAGS
    STATIC_LIBRARY_FLAGS_DEBUG
    STATIC_LIBRARY_FLAGS_RELEASE
    SUFFIX
    TYPE
    VERSION
    VS_DOTNET_REFERENCES
    VS_GLOBAL_WHATEVER
    VS_GLOBAL_KEYWORD
    VS_GLOBAL_PROJECT_TYPES
    VS_KEYWORD
    VS_SCC_AUXPATH
    VS_SCC_LOCALPATH
    VS_SCC_PROJECTNAME
    VS_SCC_PROVIDER
    VS_WINRT_EXTENSIONS
    VS_WINRT_REFERENCES
    WIN32_EXECUTABLE
    XCODE_ATTRIBUTE_WHATEVER
    IS_TEST_EXECUTABLE
  )
  map()
  kv(name ${target})
  kv(project_name ${PROJECT_NAME})


  foreach(property ${props})
    get_property(isset TARGET ${target} PROPERTY ${property} SET)
    if(isset)
        get_property(value TARGET ${target} PROPERTY ${property})
        key("${property}")
        val("${value}")    
    endif()
  endforeach()
  end()
  
  ans(res)
  return_ref(res)
endfunction()




function(tick)

  if(___ticking)
    _return()
  endif()
  set(___ticking true)
  map_set(globaltick n 0)
  function(tick)
  if(___ticking)
    _return()
  endif()
  set(___ticking true)
  map_set(globaltick val true)
  map_tryget(globaltick n)
  ans(n)
  math(EXPR n "${n} + 1")
  math(EXPR res "${n} % 600")
  math(EXPR donottick "${n} % 10")
  if(donottick STREQUAL 0)
    echo_append(".")
  endif()

  if("${res}" STREQUAL 0)
    _message("")
    set(n 0)
  endif()
  map_set(globaltick n "${n}")


  endfunction()
  tick()
endfunction()





function(tock)
  map_tryget(globaltick val)
  ans(res)
  if(res)
    _message("")
    map_set(globaltick val false)
  endif()
endfunction()




# executes the topological sort for a list of nodes (passed as varargs)
# get_hash is a function to be provided which returns the unique id for a node
# this is used to check if a node was visited previously
# expand should take a node and return its successors
# this function will return nothing if there was a cycle or if no input was given
# else it will return the topological order of the graph
function(topsort get_hash expand)
  function_import("${get_hash}" as __topsort_get_hash REDEFINE)
  function_import("${expand}" as __topsort_expand REDEFINE)
  # visitor function
  function(topsort_visit result visited node)
    # get hash for current node
    __topsort_get_hash("${node}")
    ans(hash)

    map_tryget("${visited}" "${hash}")
    ans(mark)
    
    if("${mark}" STREQUAL "temp")
      #cycle found
      return(true)
    endif()
    if(NOT mark)
      map_set("${visited}" "${hash}" temp)
      __topsort_expand("${node}")
      ans(successors)
      # visit successors
      foreach(successor ${successors})
        topsort_visit("${result}" "${visited}" "${successor}")
        ans(cycle)
        if(cycle)
      #    message("cycle found")
          return(true)
        endif()
      endforeach()

      #mark permanently
      map_set("${visited}" "${hash}" permanent)

      # add to front of result
      address_push_front("${result}" "${node}")
    endif()
    return(false)
  endfunction()


  map_new()
  ans(visited)
  address_new()
  ans(result)

  # select unmarked node and visit
  foreach(node ${ARGN})
    # get hash for node
    __topsort_get_hash("${node}")
    ans(hash)
    
    # get marking      
    map_tryget("${visited}" "${hash}")
    ans(mark)
    if(NOT mark)
      topsort_visit("${result}" "${visited}" "${node}")
      ans(cycle)
      if(cycle)
       # message("stopping with cycle")
        return()
      endif()
    endif()

  endforeach()
#  message("done")
  address_get(${result})

  return_ans()
endfunction()




# creates a value descriptor
# available options are
# REQUIRED
# available Single Value args
# DISPLAY_NAME
# DESCRIPTION
# MIN
# MAX
# Multi value args
# LABELS
# DEFAULT 

function(value_descriptor_parse id)
  set(ismap)
  set(descriptor)
  if(${ARGC} EQUAL 1)
    set(args ${ARGN})
    # it might be a map
    list_peek_front(args)
    ans(first)
    is_map("${first}" )
    ans(ismap)

    if(ismap)
      message(ismap)
      set(descriptor ${ARGV1})
    endif()
  endif()

  if(NOT descriptor)
    map_new()
    ans(descriptor)
  endif()
  
  # set default values
  map_navigate_set_if_missing("descriptor.labels" "${id}")
  map_navigate_set_if_missing("descriptor.displayName" "${id}")
  map_navigate_set_if_missing("descriptor.min" "0")
  map_navigate_set_if_missing("descriptor.max" "1")
  map_navigate_set_if_missing("descriptor.id" "${id}")
  map_navigate_set_if_missing("descriptor.description" "")
  map_navigate_set_if_missing("descriptor.default" "")
  if(ismap)
    return(${descriptor})
  endif()

  cmake_parse_arguments("" "REQUIRED" "DISPLAY_NAME;DESCRIPTION;MIN;MAX" "LABELS;DEFAULT" ${ARGN})

  if(_DISPLAY_NAME)
    map_navigate_set(descriptor.displayName "${_DISPLAY_NAME}")
  endif()

  if(_DESCRIPTION)
    map_navigate_set(descriptor.description "${_DESCRIPTION}")
  endif()
  #message("_MIN ${_MIN}")
  if("_${_MIN}" MATCHES "^_[0-9]+$")
    map_navigate_set(descriptor.min "${_MIN}")
  endif()


#  message("_MAX ${_MAX}")
  if("_${_MAX}" MATCHES "^_[0-9]+|\\*$")        
    map_navigate_set(descriptor.max "${_MAX}")
  endif()

  if(_LABELS)
    map_navigate_set(descriptor.labels "${_LABELS}")
  endif()

  if(_DEFAULT)
    map_navigate_set(descriptor.default "${_DEFAULT}")
  endif()

  return(${descriptor})

endfunction()





# pushes the specified vars to the parent scope
macro(vars_elevate)
  set(args ${ARGN})
  foreach(arg ${args})
    set("${arg}" ${${arg}} PARENT_SCOPE)
  endforeach()
endmacro()





#adds a values to parent_scopes __ans
function(yield)
    set(__yield_tmp ${__yield_tmp} ${ARGN} PARENT_SCOPE)

endfunction()





function(yield_begin)
  set(__yield_tmp PARENT_SCOPE)
endfunction()





macro(yield_return)
    return(${__yield_tmp})
endmacro()





  function(cpp_class_generate class_def)
    data("${class_def}")
    ans(class_def)

    map_tryget(${class_def} namespace)
    ans(namespace)


    map_tryget(${class_def} type_name)
    ans(type_name)

    indent_level_push(0)

    set(source)

    string(REPLACE "::" ";" namespace_list "${namespace}")

    foreach(namespace ${namespace_list})
      string_append_line_indented(source "namespace ${namespace}{")
      indent_level_push(+1)
    endforeach()


    string_append_line_indented(source "class ${type_name}{")
    indent_level_push(+1)


    indent_level_pop()
    string_append_line_indented(source "};")


    foreach(namespace ${namespace_list})
      indent_level_pop()
      string_append_line_indented(source "}")
    endforeach()



    indent_level_pop()
    # namespace
    # struct/class
    # inheritance
    # fields
    # methods
    return_ref(source)

  endfunction()





## generates a header file from a class definition
  function(cpp_class_header_generate class_def)
    data("${class_def}")
    ans(class_def)
  

    indent_level_push(0)
    set(source)
    string_append_line_indented(source "#pragma once")
    string_append_line_indented(source "")

    cpp_class_generate("${class_def}")
    ans(class_source)
    set(source "${source}${class_source}")


    string_append_line_indented(source "")

    indent_level_pop()
    return_ref(source)
  endfunction()







# queries the system for the current datetime
# returns a map containing all elements of the current date
# {yyyy: <>, MM:<>, dd:<>, hh:<>, mm:<>, ss:<>, ms:<>}

function(datetime)
  fwrite_temp("")
  ans(file)
  file_timestamp("${file}")
  ans(timestamp)
  rm("${file}")


  string(REGEX REPLACE "([0-9][0-9][0-9][0-9])\\-([0-9][0-9])\\-([0-9][0-9])T([0-9][0-9]):([0-9][0-9]):([0-9][0-9])"
   "\\1;\\2;\\3;\\4;\\5;\\6" 
   timestamp 
   "${timestamp}")
  
  list_extract(timestamp yyyy MM dd hh mm ss)
  set(ms 0)

  map_new()
  ans(dt)
  map_capture(${dt} yyyy MM dd hh mm ss ms)
  return_ref(dt)





  # old implementation
  shell_get()
  ans(shell)
  map_new()
  ans(dt)
  if("${shell}" STREQUAL cmd)
    shell_env_get("time")
    ans(time)
    shell_env_get("date")
    ans(date)
    
    string(REGEX REPLACE "([0-9][0-9])\\.([0-9][0-9])\\.([0-9][0-9][0-9][0-9]).*" "\\1;\\2;\\3" date "${date}")
    list_extract(date dd MM yyyy)
    

    string(REGEX REPLACE "([0-9][0-9]):([0-9][0-9]):([0-9][0-9]),([0-9][0-9]).*" "\\1;\\2;\\3;\\4" time "${time}")
    list_extract(time hh mm ss ms)

    map_capture(${dt} yyyy MM dd hh mm ss ms)

    return("${dt}")
  else()

    message(WARNING "cmakepp's datetime is not implemented  for your system")
    set(yyyy)
    set(MM)
    set(dd)
    set(hh)
    set(mm)
    set(ss)
    set(ms)
    
    map_capture(${dt} yyyy MM dd hh mm ss ms)

    return("${dt}")

  endif()
endfunction()




## returns the number of milliseconds since epoch
function(millis)

  compile_tool(millis "
    #include <iostream>
    #include <chrono>
    int main(int argc, const char ** argv){
     //std::cout << \"message(whatup)\"<<std::endl;
     //std::cout << \"obj(\\\"{id:'1'}\\\")\" <<std::endl;
     auto now = std::chrono::system_clock::now();
     auto duration = now.time_since_epoch();
     auto millis = std::chrono::duration_cast<std::chrono::milliseconds>(duration).count();
     std::cout<< \"set_ans(\" << millis << \")\";
     return 0;
    }"
    )
  millis(${ARGN})
  return_ans()
endfunction()






# creates a breakpoint 
# usage: breakpoint(${CMAKE_CURRENT_LIST_FILE} ${CMAKE_CURRENT_LIST_LINE})
function(breakpoint file line) 
  if(NOT DEBUG_CMAKE)
    return()
  endif()
  message("breakpoint reached ${file}:${line}")
  while(1)
    echo_append("> ")
    read_line()
    ans(cmd)
    if("${cmd}" STREQUAL "")
      message("continuing execution")
      break()
    endif()

    
    if("${cmd}" MATCHES "^\\$.*")
      string(SUBSTRING "${cmd}" 1 -1 var)
      

      get_cmake_property(_variableNames VARIABLES)
      foreach(v ${_variableNames})
        if("${v}" MATCHES "${cmd}")
          dbg("${v}")

        endif()
      endforeach()

    endif()
    



  endwhile()
endfunction()





function(performance_init)
  map_new()
  ans(perfmap)
  map_set(global __performance ${perfmap})

  function(performance_init)
      
  endfunction()

endfunction()

function(performance_sample file line)
  
  map_get(global __performance)

endfunction()

function(performance_report)

endfunction()





function(print_call_counts)
	get_property(props GLOBAL PROPERTY "function_calls")
	set(countfunc "(current) return_truth(\${current} STREQUAL \${it})")
	foreach(prop ${props})
		get_property(call_count GLOBAL PROPERTY "call_count_${prop}")
		get_property(callers GLOBAL PROPERTY "call_count_${prop}_caller")


		message("${prop}: ${call_count}")
	endforeach()
endfunction()




function(print_commands)

get_cmake_property(_variableNames COMMANDS)
foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}")
endforeach()

endfunction()





function(print_function func)
	function_lines_get( "${func}")
  ans(lines)
	set(i "0")
	foreach(line ${lines})		
		message(STATUS "LINE ${i}: ${line}")
		math(EXPR i "${i} + 1")
	endforeach()
endfunction()




macro(print_locals)

  get_cmake_property(_variableNames VARIABLES)
  foreach (_variableName ${_variableNames})
      message(STATUS "${_variableName}=${${_variableName}}")
  endforeach()

endmacro()




function(print_macros)
get_cmake_property(_variableNames MACROS)
foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}")
endforeach()
endfunction()





 function(print_multi n)


  set(headers index ${ARGN})
  set(header_lengths )
  foreach(header ${headers})
    string(LENGTH "${header}" header_len)
    math(EXPR header_len "${header_len} + 1")
    list(APPEND header_lengths ${header_len})
  endforeach()

  string(REPLACE ";" " " headers "${headers}")
  message("${headers}")

  if(${n} LESS 0)
    return()
  endif()

  foreach(i RANGE 0 ${n})
    set(current_lengths ${header_lengths})
    list_pop_front(current_lengths )
    ans(current_length)
    echo_append_padded("${current_length}" "${i}")
    foreach(arg ${ARGN})

      list_pop_front(current_lengths )
      ans(current_length)
      is_map("${${arg}}")
      ans(ismap)
      if(ismap)
        map_tryget(${${arg}} ${i})
        ans(val)
      else()
        list(GET ${arg} ${i} val)
      endif()

      echo_append_padded("${current_length}" "${val}")
    endforeach()  
    message(" ")
  endforeach()
 endfunction()





#prints result
function(print_result result)
  list(LENGTH argc "${result}" )
  if("${argc}" LESS 2)
    message("${result}")
  else()
    foreach(arg ${result})
      message("${arg}")
    endforeach()
  endif()
endfunction()






# prints the variables name and value as a STATUS message
macro(print_var varname)
  message(STATUS "${varname}: ${${varname}}")
endmacro()





## prints the specified variables names and their values in a single line
## e.g.
## set(varA 1)
## set(varB abc)
## print_vars(varA varB)
## output:
##  varA: '1' varB: 'abc'
function(print_vars)
  set(__print_vars_args "${ARGN}")
  list_extract_flag(__print_vars_args --plain)
  ans(__print_vars_plain)
  set(__str)
  foreach(__print_vars_arg ${__print_vars_args})
    assign(____cur = ${__print_vars_arg})
    if(NOT __print_vars_plain)
      json("${____cur}")
      ans(____cur)
    else()
      set(____cur "'${____cur}'")
    endif()

    string_shorten("${____cur}" "300")
    ans(____cur)
    set(__str "${__str} ${__print_vars_arg}: ${____cur}")

  endforeach()
  message("${__str}")
endfunction()





  function(eval_predicate)
    arguments_encoded_list2(0 ${ARGC})
    ans(arguments)

    regex_cmake()


    string(REGEX REPLACE "{([^}]*)}" "\\1" arguments "${arguments}")

    cmake_arguments_quote_if_necessary(${arguments})
    ans(arguments)

    set(predicate)
    foreach(arg ${arguments})
      encoded_list_decode("${arg}")
      ans(arg)
      set(predicate "${predicate} ${arg}")
    endforeach()

    #_message("${predicate}")
    set(code "
      if(${predicate})
        set_ans(true)
      else()
        set_ans(false)
      endif()
    ")

  #  _message("${code}")
    eval("${code}")
    return_ans()
  endfunction()




## `(<event-id>):<event>`
##
## tries to get the `<event>` identified by `<event-id>`
## if it does not exist a new `<event>` is created by  @markdown_see_function("event_new(...)")
function(event )
  set(event_id ${ARGN}) 
  set(event)
  if(event_id)
    event_get("${event_id}")
    ans(event)
  endif()
  if(NOT event)
    event_new(${event_id})
    ans(event)
  endif()
  return_ref(event)
endfunction()





## `()-> <event>`
##
## returns the global events map it contains all registered events.
function(events)

  function(events)
    map_get(global events)
    ans(events)
    return_ref(events)
  endfunction()

  map_new()
  ans(events)
  map_set(global events ${events})
  events(${ARGN})
  return_ans()
endfunction()





## `(<event-id...>)-><event tracker>`
##
## sets up a function which listens only to the specified events
## 
function(events_track)
  function_new()
  ans(function_name)

  map_new()
  ans(map)

  eval("
    function(${function_name})
      map_new()
      ans(event_args)
      map_tryget(\${event} event_id)
      ans(event_id)
      map_set(\${event_args} id \${event_id})
      map_set(\${event_args} args \${ARGN})
      map_set(\${event_args} event \${event})
      map_append(${map} \${event_id} \${event_args})
      map_append(${map} event_ids \${event_id})
      return(\${event_args})
    endfunction()
  ")

  foreach(event ${ARGN})
    event_addhandler(${event} ${function_name})
  endforeach()

  return(${map})
endfunction()




## `event_addhandler(<~event> <~callable>)-><event handler>`
##
## adds an event handler to the specified event. returns an `<event handler>`
## which can be used to remove the handler from the event.
##
function(event_addhandler event handler)
  event("${event}")
  ans(event)

  event_handler("${handler}")
  ans(handler)

  ## then only append function 
  map_append_unique("${event}" handlers "${handler}")
 
  return(${handler})  
endfunction()






## `()-><null>`
##
## only usable inside event handlers. cancels the current event and returns
## after this handler.
function(event_cancel)
  address_set(${__current_event_cancel} true)
  return()
endfunction()




## `(<~event>)-><void>`
##
## removes all handlers from the specified event
function(event_clear event)
  event_get("${event}")
  ans(event)

  event_handlers("${event}")
  ans(handlers)

  foreach(handler ${handlers})
    event_removehandler("${event}" "${handler}")
  endforeach()  

  return()
endfunction()






## `(<~event> <args:<any...>>)-><any...>`
##
## emits the specified event. goes throug all event handlers registered to
## this event and 
## if event handlers are added during an event they will be called as well
##
## if a event calls event_cancel() 
## all further event handlers are disregarded
##
## returns the accumulated result of the single event handlers
function(event_emit event)
  is_event("${event}")
  ans(is_event)
  
  if(NOT is_event)
    event_get("${event}")
    ans(event)
  endif()


  if(NOT event)
    return()
  endif()


  set(result)

  set(previous_handlers)
  # loop aslong as new event handlers are appearing
  # 
  address_new()
  ans(__current_event_cancel)
  address_set(${__current_event_cancel} false)
  while(true)
    ## 
    map_tryget(${event} handlers)
    ans(handlers)
    list_remove(handlers ${previous_handlers} "")
    list(APPEND previous_handlers ${handlers})

    list_length(handlers)
    ans(length)
    if(NOT "${length}" GREATER 0) 
      break()
    endif()

    foreach(handler ${handlers})

      event_handler_call(${event} ${handler} ${ARGN})
      ans(success)
      list(APPEND result "${success}")
      ## check if cancel is requested
      address_get(${__current_event_cancel})
      ans(break)
      if(break)
        return_ref(result)
      endif()
    endforeach()
  endwhile()

  return_ref(result)
endfunction() 





## `(<~event>)-><event>`
##  
## returns the `<event>` identified by `<event-id>` 
## if the event does not exist `<null>` is returned.
function(event_get event)
  events()
  ans(events)

  is_event("${event}")
  ans(is_event)

  if(is_event)
    return_ref(event)
  endif()
  
  map_tryget(${events} "${event}")
  return_ans()
endfunction()





## `(<~callable>)-><event handler>` 
##
## creates an <event handler> from the specified callable
## and returns it. a `event_handler` is also a callable
function(event_handler callable)
  callable("${callable}")
  ans(event_handler)
  return_ref(event_handler)
endfunction()





## `(<event>)-><event handler...>`
##
## returns all handlers registered for the event
function(event_handlers event)
  event_get("${event}")
  ans(event)

  if(NOT event)
    return()
  endif()

  map_tryget(${event} handlers)
  return_ans()

endfunction()




## `(<event> <event handler>)-><any>`
##
## calls the specified event handler for the specified event.
function(event_handler_call event event_handler)
  callable_call("${event_handler}" ${ARGN})
  ans(res)
  return_ref(res)
endfunction()





## `(<?event-id>)-><event>`
##
## creates an registers a new event which is identified by
## `<event-id>` if the id is not specified a unique id is generated
## and used.
## 
## returns a new <event> object: 
## {
##   event_id:<event-id>
##   handlers: <callable...> 
##   ... (psibbly cancellable, aggregations)
## }
## also defines a global function called `<event-id>` which can be used to emit the event
##
function(event_new)
  set(event_id ${ARGN})
  if(NOT event_id)
    identifier(event)
    ans(event_id)
  endif()

  if(COMMAND ${event_id})
    message(FATAL_ERROR "specified event already exists")
  endif()

  ## curry the event emit function and create a callable from the event
  curry3(${event_id}() => event_emit("${event_id}" /*))
  ans(event)

  callable("${event}")
  ans(event)  


  curry3(() => event_addhandler("${event_id}" /*))
  ans(add_handler)

  curry3(() => event_removehandler("${event_id}" /*))
  ans(remove_handler)

  curry3(() => event_clear("${event_id}" /*))
  ans(clear)



  ## set event's properties
  map_set(${event} event_id "${event_id}")
  map_set(${event} handlers)
  map_set(${event} add ${add_handler})
  map_set(${event} remove ${remove_handler})
  map_set(${event} clear ${clear})

  ## register event globally
  events()
  ans(events)
  map_set(${events} "${event_id}" ${event})

  return(${event})  
endfunction()

## faster version (does not use curry but a custom implementation)
function(event_new)
  set(event_id ${ARGN})
  if(NOT event_id)
    identifier(event)
    ans(event_id)
  endif()

  if(COMMAND ${event_id})
    message(FATAL_ERROR "specified event already exists")
  endif()

  ## curry the event emit function and create a callable from the event

  function_new()
  ans(add_handler)
  function_new()
  ans(remove_handler)
  function_new()
  ans(clear)
  eval("
    function(${event_id})
      event_emit(\"${event_id}\" \${ARGN})
      return_ans()
    endfunction()
    function(${add_handler})
      event_addhandler(\"${event_id}\" \${ARGN})
      return_ans()
    endfunction()
    function(${remove_handler})
      event_removehandler(\"${event_id}\" \${ARGN})
      return_ans()
    endfunction()
    function(${clear})
      event_clear(\"${event_id}\" \${ARGN})
      return_ans()
    endfunction()

  ")

  callable("${event_id}")
  ans(event)  

  ## set event's properties
  map_set(${event} event_id "${event_id}")
  map_set(${event} handlers)
  map_set(${event} add ${add_handler})
  map_set(${event} remove ${remove_handler})
  map_set(${event} clear ${clear})

  ## register event globally
  events()
  ans(events)
  map_set(${events} "${event_id}" ${event})

  return(${event})  
endfunction()








## `(<event handler>)-><bool>`
##
## removes the specified handler from the event idenfied by event_id
## returns true if the handler was removed
function(event_removehandler event handler)

  event("${event}")
  ans(event)
  
  if(NOT event)
    return(false)
  endif()


  event_handler("${handler}")
  ans(handler)


  map_remove_item("${event}" handlers "${handler}")
  ans(success)
  
  return_truth("${success}")
  
endfunction()






## `(<any>)-><bool>`
##
## returns true if the specified value is an event
## an event is a ref which is callable and has an event_id
##
function(is_event event)
  is_address("${event}")
  ans(is_ref)
  if(NOT is_ref)
    return()
  endif()
  is_callable("${event}")
  ans(is_callable)
  if(NOT is_callable)
    return(false)
  endif()

  map_has(${event} event_id)
  ans(has_event_id)
  if(NOT has_event_id)
    return(false)
  endif()

  return(true)
endfunction()




## `archive_isvalid(<path>)-> <bool>`
##
## returns true if the specified path identifies an archive 
## file
function(archive_isvalid file)
  mime_type("${file}")
  ans(types)

  list_contains(types "application/x-gzip")
  ans(is_archive)


  return_ref(is_archive)
endfunction()





function(archive_ls archive)
  path_qualify(archive)


  mime_type("${archive}")
  ans(types)


  if("${types}" MATCHES "application/x-gzip")
    checksum_file("${archive}")
    ans(key)
    string_cache_return_hit(archive_ls_cache "${key}")


    tar_lean(tf "${archive}")
    ans_extract(erro)
    ans(files)

    tar_lean(tf "${archive}")
    ans_extract(error)
    ans(files)

    if(error)
      error("tar exited with {result.error}")
      return()
    endif()


    string(REGEX MATCHALL "(^|\n)([^\n]+)(\n|$)" files "${files}")
    string(REGEX REPLACE "(\r|\n)" "" files "${files}")
    
    string_cache_update(archive_ls_cache "${key}" "${files}")
    return_ref(files)

  else()
    message(FATAL_ERROR "${archive} unsupported compression: '${types}'")
  endif()

 endfunction()





## returns all files which match the specified regex
## the regex must match the whole filename
function(archive_match_files archive regex)
  set(args ${ARGN})

  list_extract_flag(args --single)
  ans(single)
  list_extract_flag(args --first)
  ans(first)

  path_qualify(archive)

  mime_type("${archive}")
  ans(types)


  if("${types}" MATCHES "application/x-gzip")

    archive_ls("${archive}")
    ans(files)
    string(REGEX MATCHALL "(^|;)(${regex})(;|$)" files "${files}")
    set(files ${files}) # necessary because of leading and trailing ;
  else()
    message(FATAL_ERROR "${archive} unsupported compression: '${types}'")
  endif()

  if(single)
    list(LENGTH files len)
    if(NOT "${len}" EQUAL 1)
      set(files)
    endif()
  endif()

  if(first)
    list_pop_front(files)
    ans(files)
  endif()

  return_ref(files)
endfunction()






function(archive_read_file archive file)
  path_qualify(archive)
  mktemp()
  ans(temp_dir)
  uncompress_file("${temp_dir}" "${archive}" "${file}")
  fread("${temp_dir}/${file}")
  ans(content)
  rm("${temp_dir}")
  return_ref(content) 
endfunction()







function(archive_read_file_match archive regex)
  path_qualify(archive)
  archive_match_files("${archive}" "${regex}")
  ans(file_path)
  list(LENGTH file_path count)
  if(NOT "${count}" EQUAL 1)
    return()
  endif()

  archive_read_file("${archive}" "${file_path}")
  return_ans()
endfunction()






# compresses all files specified in glob expressions (relative to pwd) into ${target_file} tgz file
# usage: compress(<file> [<glob> ...]) - 
# 
function(compress target_file)
  set(args ${ARGN})
  
  list_extract_labelled_value(args --format)
  ans(format)

  ## try to resolve format by extension
  if("${format}_" STREQUAL "_")
    mime_type_from_filename("${target_file}")
    ans(format)
  endif()

  ## set default formt to application/x-gzip
  if("${format}_" STREQUAL "_")
    set(format "application/x-gzip")
  endif()

  if(format STREQUAL "application/x-gzip")
    compress_tgz("${target_file}" ${args})
    return_ans()
  else()
    message(FATAL_ERROR "format not supported: ${format}, target_file: ${target_file}")
  endif()
endfunction()







function(compress_tgz target_file)
  set(args ${ARGN})
  # target_file file
  path_qualify(target_file)

  # get all files to compress
  glob(${args} --relative)
  ans(paths)

  # compress all files into target_file using paths relative to pwd()
  tar_lean(cvzf "${target_file}" ${paths})
  ans_extract(error)
  return_ans()
endfunction()




## returns true if the specified file is a tar archive 
function(file_istarfile file)
	path_qualify(file)
	if(NOT EXISTS "${file}")
		return(false)
	endif()
	if(IS_DIRECTORY "${file}")
		return(false)
	endif()
	tar_lean(ztvf "${file}")
	ans_extract(res)
	ans(rest)

	if(res)
		return(false)
	endif()

	return(true)
	
endfunction()









# tar command 
# use cvzf to compress files relative to pwd() to a tgz file 
# use xzf to uncompress a tgz file to the pwd()
function(tar)
  cmake(-E tar ${ARGN})
  return_ans()
endfunction()






function(tar_lean)
  cmake_lean(-E tar ${ARGN})
  return_ans()
endfunction()




## uncompresses the file specified into the current pwd()
function(uncompress file)
  mime_type("${file}")
  ans(types)

  if("${types}" MATCHES "application/x-gzip")
    dir_ensure_exists(".")  
    path_qualify(file)
    tar_lean(xzf "${file}" ${ARGN})
    ans_extract(error)
    return_ans()
  else()
    message(FATAL_ERROR "unsupported compression: '${types}'")
  endif()
endfunction()










#uncompresses specific files from archive specified by varargs and stores them in target_dir directory
function(uncompress_file target_dir archive)
  set(files ${ARGN})

  path_qualify(archive)

  mime_type("${archive}")
  ans(types)


  if("${types}" MATCHES "application/x-gzip")
    pushd("${target_dir}" --create)
      tar_lean(-zxvf "${archive}" ${files})
      ans_extract(error)
      ans(result)
    popd()
    return_ref(result)
  else()
    message(FATAL_ERROR "unsupported compression: '${types}'")
  endif()

endfunction()






## ensures that the directory specified exists 
## the directory is qualified with path()
function(dir_ensure_exists path)
  path("${path}")
  ans(path)
  if(EXISTS "${path}")
    if(IS_DIRECTORY "${path}")
      return("${path}")
    endif()
    return()
  endif()
  mkdir("${path}")
  return_ans()
endfunction()




## returns true iff specified path does not contain any files
function(dir_isempty path)
  ls("${path}")
  ans(files)
  list(LENGTH files len)
  if(len)
    return(false)
  endif()
  return(true)
endfunction()




function(fappend path)
  path("${path}")
  ans(path)
  file(APPEND "${path}" ${ARGN})
  return()
endfunction()




  ## compares the specified files
  ## returning true if their content is the same else false
  function(fequal lhs rhs)
    path_qualify(lhs)
    path_qualify(rhs)

    cmake(-E compare_files "${lhs}" "${rhs}" --exit-code)
    ans(error)
    
    if(error)
      return(false)
    endif()
    return(true)
  endfunction()





##
##
## tries to deserialize a file file.*  
function(fopen_data file)
  glob_path("${file}")
  ans(file)

  if(NOT EXISTS "${file}" OR IS_DIRECTORY "${file}")
    glob("${file}.*") 
    ans(file)
    list(LENGTH file len)
    if(NOT ${len} EQUAL 1)
      return()
    endif()
    if(IS_DIRECTORY "${file}")
      return()
    endif()
  endif()

  fread_data("${file}" ${ARGN})
  return_ans()
endfunction()




## prints the specified file to the console
function(fprint path)
  fread("${path}")
  ans(res)
  _message("${res}")
  return()
endfunction()


function(fprint_try path)
  path_qualify(path)
  if(EXISTS "${path}")
    fprint("${path}")
  endif()
  returN()
endfunction()




# reads the file specified and returns its content
function(fread path)
  path("${path}")
  ans(path)
  file(READ "${path}" res)
  return_ref(res)
endfunction()




## tries to read the spcified file format
function(fread_data path)
  set(args ${ARGN})

  path_qualify(path)
  
  list_pop_front(args)
  ans(mime_type)

  if(NOT mime_type)

    mime_type("${path}")
    ans(mime_type)

    if(NOT mime_type)
      return()
    endif()

  endif()


  if("${mime_type}" MATCHES "application/json")
    json_read("${path}")
    return_ans()
  elseif("${mime_type}" MATCHES "application/x-quickmap")
    qm_read("${path}")
    return_ans()
  elseif("${mime_type}" MATCHES "application/x-serializedcmake")
    cmake_read("${path}")
    return_ans()
  else()
    return()
  endif()

endfunction()





# reads the file specified and returns its content
function(fread_lines path)
  path_qualify(path)
  set(args ${ARGN})

  list_extract_labelled_keyvalue(args --regex REGEX)
  ans(regex)
  list_extract_labelled_keyvalue(args --limit-count LIMIT_COUNT)
  ans(limit_count)
  list_extract_labelled_keyvalue(args --limit-input LIMIT_INPUT)
  ans(limit_input)
  list_extract_labelled_keyvalue(args --limit-output LIMIT_OUTPUT)
  ans(limit_output)
  list_extract_labelled_keyvalue(args --length-minimum LENGTH_MINIMUM)
  ans(length_minimum)
  list_extract_labelled_keyvalue(args --length-maximum LENGTH_MAXIMUM)
  ans(length_maximum)
  list_extract_flag_name(args --newline-consume NEWLINE_CONSUME)
  ans(newline_cosume)
  list_extract_flag_name(args --no-hex-conversion NO_HEX_CONVERSION)
  ans(no_hex_conversion)


  file(STRINGS "${path}" res 
    ${limit_count} 
    ${limit_input} 
    ${limit_output} 
    ${length_minimum} 
    ${length_maximum}
    ${newline_cosume}
    ${regex}
    ${no_hex_conversion}
  )

  return_ref(res)
endfunction()






  ## this is a hard hack to read unicode 16 files
  ##  it reads the file by lines and concatenates the result which removes all linebreaks  
  ## please don't use this :)
  function(fread_unicode16 path)
    path("${path}")
    ans(path)
    file(STRINGS "${path}" lines)  
    string(CONCAT res ${lines})
    return_ref(res)
  endfunction()






## returns the timestamp for the specified path
function(ftime path)
  path_qualify(path)

  if(NOT EXISTS "${path}")
    return()
  endif()

  file(TIMESTAMP "${path}" res)

  return_ref(res)
endfunction()




# writs argn to the speicified file creating it if it does not exist and 
# overwriting it if it does.
function(fwrite path)
  path_qualify(path)
  file(WRITE "${path}" "${ARGN}")
  event_emit(on_fwrite "${path}")
  return_ref(path)
endfunction()




  ## fwrite_data(<path> ([--mimetype <mime type>]|[--json]|[--qm]) <~structured data?>) -> <structured data>
  ##
  ## writes the specified data into the specified target file (overwriting it if it exists)
  ##
  ## fails if no format could be chosen
  ##
  ## format:  if you do not specify a format by passing a mime-type
  ##          or type flag the mime-type is chosen by analysing the 
  ##          file extension - e.g. *.qm files serialize to quickmap
  ##          *.json files serialize to json
  ##
  function(fwrite_data target_file)
    set(args ${ARGN})

    ## choose mime type
    list_extract_labelled_value(args --mime-type)
    ans(mime_types)

    list_extract_flag(args --json)
    ans(json)

    list_extract_flag(args --qm)
    ans(quickmap)

    list_extract_flag(args --cmake)
    ans(cmake)

    if(cmake)
      set(mime_types application/x-serializedcmake)
    endif()

    if(json)
      set(mime_types application/json)
    endif()

    if(quickmap)
      set(mime_types application/x-quickmap)
    endif()


    if(NOT mime_types)
      mime_type_from_filename("${target_file}")
      ans(mime_types)
      if(NOT mime_types)
        set(mime_types "application/json")
      endif()
    endif()

    ## parse data
    data(${args})
    ans(data)


    ## serialize data
    if("${mime_types}" MATCHES "application/json")
      json_indented("${data}")
      ans(serialized)
    elseif("${mime_types}" MATCHES "application/x-serializedcmake")
      cmake_serialize("${data}")
      ans(serialized)
    elseif("${mime_types}" MATCHES "application/x-quickmap")
      qm_serialize("${data}")
      ans(serialized)
    else()
      message(FATAL_ERROR "serialization to '${mime_types}' is not supported")
    endif()

    ## write and return data
    fwrite("${target_file}" "${serialized}")
    return_ref(data)
  endfunction()





function(file_isjsonfile file)
  return(false)
endfunction()





function(file_isqmfile file)
    path_qualify(file)
    if(NOT EXISTS "${file}" OR IS_DIRECTORY "${file}")
      return(false)
    endif()
  file(READ "${file}" result LIMIT 3)
  if(result STREQUAL "#qm")
    return(true)
  endif()

  return(false)

endfunction()





function(file_isserializedcmakefile file)
  path_qualify(file)
  if(NOT EXISTS "${file}" OR IS_DIRECTORY "${file}")
    return(false)
  endif()
  file(READ "${file}" result LIMIT 7)
  if("${result}" MATCHES "^#cmake")
    return(true)
  endif()
  return(false)
endfunction()





## writes a file_map to the pwd.
## empty directories are not created
## fm is parsed according to obj()
function(file_map_write fm)


  # define callbacks for building result
  function(fmw_dir_begin)
    map_tryget(${context} current_key)
    ans(key)
    if("${map_length}" EQUAL 0)
      return()
    endif()
    if(key)
      pushd("${key}" --create)
    else()
      pushd()
    endif()
  endfunction()
  function(fmw_dir_end)
    if(NOT "${map_length}" EQUAL 0)    
      popd()
    endif()
  endfunction()
  function(fmw_path_change)
    map_set(${context} current_key "${map_element_key}")
  endfunction()

  function(fmw_file)
    map_get(${context} current_key) 
    ans(key)
    fwrite("${key}" "${node}")
  endfunction()

   map()
    kv(value              fmw_file)
    kv(map_begin          fmw_dir_begin)
    kv(map_end            fmw_dir_end)
    kv(list_begin         fmw_file)
    kv(map_element_begin  fmw_path_change)
  end()
  ans(file_map_write_cbs)
  function_import_table(${file_map_write_cbs} file_map_write_callback)

  # function definition
  function(file_map_write fm)            
    obj("${fm}")
    ans(fm)

    map_new()
    ans(context)
    dfs_callback(file_map_write_callback ${fm} ${ARGN})
    map_tryget(${context} files)
    return_ans()  
  endfunction()
  #delegate
  file_map_write(${fm} ${ARGN})
  return_ans()
endfunction()

function(file_map_read)
  path("${ARGN}")
  ans(path)
  message("path ${path}")
  
  file(GLOB_RECURSE paths RELATIVE "${path}" ${path}/**)

  message("paths ${paths}")



  return_ans()

endfunction()





## 
## 
## creates a temporary file containing the specified content
## returns the path for that file 
function(fwrite_temp content)
  set(ext ${ARGN})

  if(NOT ext)
    set(ext ".txt")
  endif()

  cmakepp_config(temp_dir)
  ans(temp_dir)

  path_vary("${temp_dir}/fwrite_temp${ext}")
  ans(temp_path)

  fwrite("${temp_path}" "${content}")

  return_ref(temp_path)

endfunction()




## `(<glob expression...> [--relative] [--recurse]) -> <qualified path...>|<relative path...>`
##
## **flags**:
## * `--relative` causes the output to be paths realtive to current `pwd()`
## * `--recurse` causes the glob expression to be applied recursively
## **scope**
## * `pwd()` influences the relative paths
## **returns**
## * list of files matching the specified glob expressions 
function(glob)
  set(args ${ARGN})
  list_extract_flag(args --relative)
  ans(relative)
  
  list_extract_flag(args --recurse)
  ans(recurse)

  glob_paths(${args})
  ans(globs)

  if(recurse)
    set(glob_command GLOB_RECURSE)
  else()
    set(glob_command GLOB)
  endif()

  if(relative)
    pwd()
    ans(pwd)
    set(relative RELATIVE "${pwd}")
  else()
    set(relative)
  endif()

  set(paths)

  if(globs)
    file(${glob_command} paths ${relative} ${globs})
    list_remove_duplicates(paths)
  endif()

  return_ref(paths)
endfunction()






  ## glob_expression_parse(<glob ignore path...>) -> {include:<glob path>, exclude:<glob path>}
  ##
  ##
  function(glob_expression_parse)
    set(args ${ARGN})

    is_map("${args}")
    ans(ismap)
    if(ismap)
      return_ref(args)
    endif()

    string(REGEX MATCHALL "![^;]+" exclude "${args}")
    string(REGEX MATCHALL "[^!;]+" exclude "${exclude}")
    string(REGEX MATCHALL "(^|;)[^!;][^;]*" include "${args}")
    string(REGEX MATCHALL "[^;]+" include "${include}")


    map_capture_new(include exclude)
    ans(res)
    return_ref(res)

  endfunction()







  ## glob_ignore(<glob ignore expression...> [--relative] [--recurse]) -> <path...>
  ##
  ## 
  function(glob_ignore)
    set(args ${ARGN})
    list_extract_flag_name(args --relative)
    ans(relative)
    list_extract_flag_name(args --recurse)
    ans(recurse)


    glob_expression_parse(${args})
    ans(glob_expression)

    map_import_properties(${glob_expression} include exclude)

    glob(${relative} ${include} ${recurse})
    ans(included_paths)

    glob(${relative} ${exclude} ${recurse})
    ans(excluded_paths)
    if(excluded_paths)
      list(REMOVE_ITEM included_paths ${excluded_paths})
    endif()
    return_ref(included_paths)
  endfunction()
  





## `(<directory> <glob expression>)-><qualified director>`
## 
## 
## finds the closest parent dir (or dir itself)
## that contains any of the specified glob expressions
## (also see file_glob for syntax)
function(glob_parent_dir_containing )
  glob_up(0 ${ARGN})
  ans(matches)
  list_peek_front(matches)
  ans(first_match)
  if(NOT first_match)
    return()
  endif()

  path_component("${first_match}" PATH)
  ans(first_match)

  return_ref(first_match)
endfunction()





  ## glob_paths(<unqualified glob path>) -> <qualified glob path.>
  ##
  ## 
  function(glob_path glob)
    string_take_regex(glob "[^\\*\\[{]+")
    ans(path)

    string(REGEX MATCH "[^/]+$" match "${path}")
    set(glob "${match}${glob}")
    string(REGEX REPLACE "[^/]+$" "" path "${path}")

    path_qualify(path)

    if(glob)
      set(path "${path}/${glob}")
    endif()
    return_ref(path)
 endfunction()






  ## glob_paths(<unqualified glob path...>) -> <qualified glob path...>
  ##
  ## 
 function(glob_paths)
  set(result)
  foreach(path ${ARGN})
    glob_path(${path})
    ans(res)
    list(APPEND result ${res})
  endforeach()
  return_ref(result)
 endfunction()





# applies the glob expressions (passed as varargs)
# to the first n parent directories starting with the current dir
# order of result is in deepest path first
# 0 searches parent paths up to root
# warning do not use --recurse and unlimited depth as it would probably take forever
# @todo extend to quit search when first result is found
function(glob_up n)
  set(args ${ARGN})

  # extract dir
  set(path)
  path("${path}")
  ans(path)

  set(globs ${args})

  # /tld is appended because only its parent dirs are gotten 
  path_parent_dirs("${path}/tld" ${n})
  ans(parent_dirs)

  set(all_matches)
  foreach(parent_dir ${parent_dirs})
    glob("${parent_dir}" ${globs})
    ans(matches)
    list(APPEND all_matches ${matches})
  endforeach()
  return_ref(all_matches)
endfunction()





## `(<?path>)-> <qualified path...>`
##
## returns a list of files and folders in the specified directory
##
function(ls)
  path("${ARGN}")
  ans(path)

  if(IS_DIRECTORY "${path}")
    set(path "${path}/*")
  endif()

  file(GLOB files "${path}")
  return_ref(files)
endfunction()







## `()-><qualified path>`
##
## returns the current users home directory on all OSs
## 
function(home_dir)
  shell_get()
  ans(shell)
  if("${shell}" STREQUAL "cmd")
    shell_env_get("HOMEDRIVE")
    ans(dr)
    shell_env_get("HOMEPATH")
    ans(p)
    set(res "${dr}${p}")
    file(TO_CMAKE_PATH "${res}" res)
    #path("${res}")
    #ans(res)
  elseif("${shell}" STREQUAL "bash")
    shell_env_get(HOME)
    ans(res)
  else()
    message(FATAL_ERROR "supported shells: cmd & bash")
  endif() 
  eval("
    function(home_dir)
      set(__ans \"${res}\" PARENT_SCOPE)
    endfunction()
      ")
  return_ref(res)
endfunction()





## `(<target:<path>> <link:<path>>?)-><bool>` 
##
## creates a symlink from `<link>` to `<target>` on all operating systems
## (Windows requires NTFS filesystem)
## if `<link>` is omitted then the link will be created in the local directory 
## with the same name as the target
##
function(ln)
  wrap_platform_specific_function(ln)
  ln(${ARGN})
  return_ans()
endfunction()



function(ln_Linux target)
   set(args ${ARGN})

  path_qualify(target)

  list_pop_front(args)
  ans(link)
  if("${link}_" STREQUAL "_")
    get_filename_component(link "${target}" NAME )
  endif()

  path_qualify(link)
  execute_process(COMMAND ln -s "${target}" "${link}" RESULT_VARIABLE error ERROR_VARIABLE stderr)
  if(error)
    return(false)
  endif() 
  return(true)
endfunction()


function(ln_Windows target)
  set(args ${ARGN})

  path_qualify(link)

  list_pop_front(args)
  ans(link)

  if("${link}_" STREQUAL "_")
    get_filename_component(link "${target}" NAME )
  endif()

  path_qualify(target)


  if(EXISTS "${target}" AND NOT IS_DIRECTORY "${target}")
    set(flags "/H")
  else()
    set(flags "/D" "/J")
  endif()
  string(REPLACE "/" "\\" link "${link}")
  string(REPLACE "/" "\\" target "${target}")

 # print_vars(link target flags)
  win32_cmd_lean("/C" "mklink" ${flags} "${link}" "${target}")
  ans_extract(error)
  if(error)
    return(false)
  endif()
  return(true)
endfunction()







## returns the file type for the specified file
## only existing files can have a file type
## if an existing file does not have a specialized file type
## the extension is returned
function(mime_type file)
  path_qualify(file)

  if(NOT EXISTS "${file}")
    return(false)
  endif()

  if(IS_DIRECTORY "${file}")
    return(false)
  endif()


  mime_type_from_file_content("${file}")
  ans(mime_type)

  if(mime_type)
    return_ref(mime_type)
  endif()

  mime_type_from_filename("${file}")

  return_ans()
endfunction()





## mime_type_from_extension()->
##
## returns the mime type or types matching the specified file extension
##
function(mime_type_from_extension extension)

  if("${extension}" MATCHES "\\.(.*)")
    set(extension "${CMAKE_MATCH_1}")
  endif()

  string(TOLOWER "${extension}" extension)

  mime_type_map()
  ans(mime_types)

  map_tryget("${mime_types}" "${extension}")
  ans(mime_types)

  set(mime_type_names)
  foreach(mime_type ${mime_types})
    map_tryget("${mime_type}" name)
    ans(mime_type_name)
    list(APPEND mime_type_names "${mime_type_name}")  
  endforeach()

  return_ref(mime_type_names)
endfunction()






## mime_type_from_filename() -> 
##
## returns the mimetype for the specified filename
##
##
function(mime_type_from_filename file)
  get_filename_component(extension "${file}" EXT)
  mime_type_from_extension("${extension}")
  return_ans()
endfunction()






function(mime_type_from_file_content file)
  path_qualify(file)
  if(NOT EXISTS "${file}")
    return()
  endif()


  file_isserializedcmakefile("${file}")
  ans(is_serializedcmake)
  if(is_serializedcmake)
    return("application/x-serializedcmake")
  endif()


  file_isqmfile("${file}")
  ans(is_qm)
  if(is_qm)
    return("application/x-quickmap")
  endif()

  file_isjsonfile("${file}")
  ans(is_json)
  if(is_json)
    return("application/json")
  endif()



  file_istarfile("${file}")
  ans(is_tar)
  if(is_tar)
    return("application/x-gzip")
  endif()


  return()
endfunction()






## returns the mimetyoe object for the specified name or extension
function(mime_type_get name_or_ext)
  mime_type_map()
  ans(mm)
  map_tryget("${mm}" "${name_or_ext}")
  return_ans()
endfunction()






function(mime_type_get_extension mime_type)
    mime_type_get("${mime_type}")
    ans(mt)
    map_tryget("${mt}" extensions)
    ans(extensions)
    list_pop_front(extensions)
    ans(res)
    return_ref(res)

return()
  if(mime_type STREQUAL "application/cmake")
    return("cmake")
  elseif(mime_type STREQUAL "application/json")
    return("json")
  elseif(mime_type STREQUAL "application/x-quickmap")
    return("qm")
  elseif(mime_type STREQUAL "application/x-gzip")
    return("tgz")
  elseif(mime_type STREQUAL "text/plain")
    return("txt")
  endif()

  return()
endfunction()






## returns a map of known mime types
function(mime_type_map)
  map_new()
  ans(mime_type_map)
  map_set(global mime_types "${mime_type_map}")

  function(mime_type_map)
    map_tryget(global mime_types)
    return_ans()
  endfunction()

  mime_types_register_default()



  mime_type_map()
  return_ans()
endfunction()






## https://www.ietf.org/rfc/rfc2045.txt
function(mime_type_register mime_type)
  data("${mime_type}")
  ans(mime_type)

  map_tryget("${mime_type}" name)
  ans(name)
  if(name STREQUAL "")
    return()
  endif()

  mime_type_map()
  ans(mime_types)

  map_tryget("${mime_types}" "${name}")
  ans(existing_mime_type)
  if(existing_mime_type)
    message(FATAL_ERROR "mime_type ${name} already exists")
  endif()

  map_tryget("${mime_type}" extensions)
  ans(extensions)


  foreach(key ${name} ${extensions})
    map_append(${mime_types} "${key}" "${mime_type}")
  endforeach()

  return_ref(mime_type)

endfunction()







function(mime_types_register_default)
  mime_type_register("{
      name:'application/x-gzip',
      description:'',
      extensions:['tgz','gz','tar.gz']
  }")
  mime_type_register("{
      name:'application/zip',
      description:'',
      extensions:['zip']
  }")

  mime_type_register("{
      name:'application/x-serializedcmake',
      description:'',
      extensions:['cmake','scmake']
  }")

  mime_type_register("{
      name:'application/x-7z-compressed',
      description:'',
      extensions:['7z']
  }")

  mime_type_register("{
      name:'text/plain',
      description:'',
      extensions:['txt','asc']
  }")


  mime_type_register("{
      name:'application/x-quickmap',
      description:'CMake Quickmap Object Notation',
      extensions:['qm']
  }")



  mime_type_register("{
      name:'application/json',
      description:'JavaScript Object Notation',
      extensions:['json']
  }")



  mime_type_register("{
      name:'application/x-cmake',
      description:'CMake Script File',
      extensions:['cmake']
  }")



  mime_type_register("{
      name:'application/xml',
      description:'eXtensible Markup Language',
      extensions:['xml']
  }")


endfunction()




# changes the current directory 
function(cd)
  set(args ${ARGN})
  list_extract_flag(args --create)
  ans(create)
  list_extract_flag(args --force)
  ans(force)
  path("${args}")
  ans(path)
 # message("cd ${path}")
  if(NOT IS_DIRECTORY "${path}" AND NOT force)
    if(NOT create)
      message(FATAL_ERROR "directory '${path}' does not exist")
      return()
    endif()
    mkdir("${path}")
  endif()
  address_set(__global_cd_current_directory "${path}")
  return_ref(path)
endfunction()




# returns all directories currently on directory stack
# also see pushd popd
function(dirs)
  stack_enumerate(__global_push_d_stack)
  ans(res)
  return_ref(res)
endfunction()




# replaces the current working directory with
# the top element of the directory stack_pop and
# removes the top element
function(popd)
  stack_pop(__global_push_d_stack)
  ans(pwd)
  cd("${pwd}" ${ARGN})
  return_ans()
endfunction()





##
##
## removes the current path from the path stack
## delets the temporary directory
function(poptmp)
  pwd()
  ans(pwd)
  if(NOT "${pwd}" MATCHES "mktemp")
    message(FATAL_ERROR "cannot poptmp - path ${pwd} is not temporary ")
  endif() 
  rm(-r "${pwd}")
  popd()
  return_ans()
endfunction()




# pushes the specfied directory (or .) onto the 
# directory stack
function(pushd)
  pwd()
  ans(pwd)
  stack_push(__global_push_d_stack "${pwd}")
  if(ARGN)
    cd(${ARGN})
    return_ans()
  endif()
  return_ref(pwd)
endfunction()




## `(<?parent dir>)-><qualified path>, path_stack is pushed`
##
## pushes a temporary directory on top of the pathstack 
function(pushtmp)
  mktemp(${ARGN})
  ans(dir)
  pushd("${dir}")
  return_ans()
endfunction()





# returns the current working directory
  function(pwd)
    address_get(__global_cd_current_directory)
    return_ans()
  endfunction()





# copies the specified path to the specified target
# if last argument is a existing directory all previous files will be copied there
# else only two arguments are allow source and target
# cp(<sourcefile> <targetfile>)
# cp([<sourcefile> ...] <existing targetdir>)
function(cp)
  set(args ${ARGN})
  list_pop_back(args)
  ans(target)

  list_length(args)
  ans(len)
  path("${target}")
  ans(target)
  # single move

  if(NOT IS_DIRECTORY "${target}" )
    if(NOT "${len}" EQUAL "1")
      message(FATAL_ERROR "wrong usage for cp() exactly one source file needs to be specified")
    endif() 
    path("${args}")
    ans(source)
    # this just has to be terribly slow... 
    # i am missing a direct
    cmake_lean(-E "copy" "${source}" "${target}")
    ans_extract(error)
    if(error)
      message("failed to copy ${source} to ${target}")
    endif()
   return()
  endif()


  paths(${args})
  ans(paths)
  file(COPY ${paths} DESTINATION "${target}") 
  

  return()
endfunction()






  ## cp_content(<source dir> <target dir> <glob ignore expression...>) -> <path...> 
  ## 
  ## copies the content of source dir to target_dir respecting 
  ## the globging expressions if none are given
  ## returns the copied paths if globbing expressiosnw were used
  ## else returns the qualified target_dir
  function(cp_content source_dir target_dir)

    path_qualify(target_dir)
    path_qualify(source_dir)
    set(content_globbing_expression ${ARGN})
    if(NOT content_globbing_expression)
      cp_dir("${source_dir}" "${target_dir}")
      ans(res)
    else()
        pushd("${source_dir}")
            cp_glob("${target_dir}" ${content_globbing_expression})
            ans(res)
        popd()
    endif()
    return_ref(res)
  endfunction()




## copies the contents of source_dir to target_dir
function(cp_dir source_dir target_dir)
  path_qualify(source_dir)
  path_qualify(target_dir)
  cmake(-E copy_directory "${source_dir}" "${target_dir}" --exit-code)
  ans(error)
  if(error)
    message(FATAL_ERROR "failed to copy contents of '${source_dir}' to '${target_dir}' this often happens when file names are too long ")
  endif()
  return_ref(target_dir)
endfunction()






  ## cp_glob(<target dir> <glob. ..> )-> <path...>
  ##
  ## 
  function(cp_glob target_dir)
    set(args ${ARGN})
    
    list_extract_flag_name(args --recurse)
    ans(recurse)

    path_qualify(target_dir)

    glob_ignore(--relative ${args} ${recurse})
    ans(paths)

    pwd()
    ans(pwd)

    foreach(path ${paths})
      path_component(${path} --parent-dir)
      ans(relative_dir)
      file(COPY "${pwd}/${path}" DESTINATION "${target_dir}/${relative_dir}")
     
    endforeach()
    return_ref(paths)
  endfunction()




# creates a new directory
function(mkdir path)    
  path("${path}")
  ans(path)
  file(MAKE_DIRECTORY "${path}")
  event_emit(on_mkdir "${path}")
  return_ref(path)
endfunction()






# creates all specified dirs
function(mkdirs)
  set(res)
  foreach(path ${ARGN})
    mkdir("${path}")
    ans(p)
    list(APPEND res "${p}")    
  endforeach()
  return_ref(res)
endfunction()







# creates a temporary directory 
# you can specify an optional parent directory in which it should be created
# usage: mktemp([where])-> <absoute path>
function(mktemp)
  path_temp(${ARGN})
  ans(path)
  mkdir("${path}")
  return_ref(path)
endfunction()





# moves the specified path to the specified target
# if last argument is a existing directory all previous files will be moved there
# else only two arguments are allow source and target
# mv(<sourcefile> <targetfile>)
# mv([<sourcefile> ...] <existing targetdir>)
function(mv)
  set(args ${ARGN})
  list_pop_back(args)
  ans(target)

  list_length(args)
  ans(len)
  path("${target}")
  ans(target)
  # single move
  if(NOT IS_DIRECTORY "${target}" )
    if(NOT "${len}" EQUAL "1")
      message(FATAL_ERROR "wrong usage for mv() exactly one source file needs to be specified")
    endif()
    path("${args}")
    ans(source)
    file(RENAME "${source}" "${target}")
    return()
  endif()

  foreach(source ${args})
    path_file_name("${source}")
    ans(fn)
    mv("${source}" "${target}/${fn}")
  endforeach()

  return()
endfunction()





# removes the specified paths if -r is passed it will also remove subdirectories
# rm([-r] [<path> ...])
# files names are qualified using pwd() see path()
function(rm)
  set(args ${ARGN})
  list_extract_flag(args -r)
  ans(recurse)
  paths("${args}")
  ans(paths)
  set(cmd)
  if(recurse)
    set(cmd REMOVE_RECURSE)
  else()
    set(cmd REMOVE)
  endif()

  file(${cmd} "${paths}")
  return()
endfunction()






# creates a file or updates the file access time
# *by appending an empty string
function(touch path)

  #if("${CMAKE_MAJOR_VERSION}" LESS 3)
    function(touch path)

      path("${path}")
      ans(path)

      set(args ${ARGN})
      list_extract_flag(args --nocreate)
      ans(nocreate)

      if(NOT EXISTS "${path}" AND nocreate)
        return_ref(path)
      elseif(NOT EXISTS "${path}")
        file(WRITE "${path}" "")        
      else()
        file(APPEND "${path}" "")
      endif()


      return_ref(path)

    endfunction()
  touch("${path}")
  return_ans()
endfunction()






## `(<path>)-><qualified path>`
##
## returns the fully qualified path name for path
## if path is a fully qualified name it returns path
## else path is interpreted as the relative path 
function(path path)
  pwd()
  ans(pwd)
  path_qualify_from("${pwd}" "${path}")
  return_ans()
endfunction()








# qualify multiple paths (argn)
function(paths)
  set(res)
  foreach(path ${ARGN})
    path("${path}")
    ans(path)
    list(APPEND res ${path})
  endforeach()
  return_ref(res)
endfunction()




# makes all paths passed as varargs into paths relative to base_dir
function(paths_make_relative base_dir)
  set(res)
  get_filename_component(base_dir "${base_dir}" ABSOLUTE)

  foreach(path ${ARGN})
    path_qualify(path)
    file(RELATIVE_PATH path "${base_dir}" "${path}")
    list(APPEND res "${path}")
  endforeach()

  return_ref(res)
endfunction()










function(paths_relative path_base)
  set(res)
  foreach(path ${ARGN})
    path_relative("${path_base}" "${path}")
    ans(c)
    list(APPEND res "${c}")
  endforeach()
  return_ref(res)
endfunction()





# converts the varargs list of pahts to a map
function(paths_to_map )
  map_new()
  ans(map)
  foreach(path ${ARGN})
    path_to_map("${map}" "${path}")
  endforeach()
  return_ref(map)
endfunction()






  # combines all dirs to a single path  
  function(path_combine )
    set(args ${ARGN})
    list_to_string(args "/")
    ans(path)
    return_ref(path)
  endfunction()




# returns the specified path component for the passed path
# posibble components are
# --file-name NAME_WE
# --file-name-ext NAME
# --parent-dir PATH
# @todo: create own components 
# e.g. parts dirs extension etc. consider creating an uri type
function(path_component path path_component)
  if("${path_component}" STREQUAL "--parent-dir")
    set(path_component PATH)
  elseif("${path_component}" STREQUAL "--file-name")
    set(path_component NAME_WE)
  elseif("${path_component}" STREQUAL "--file-name-ext")
    set(path_component NAME)
  endif()
  get_filename_component(res "${path}" "${path_component}")
  return_ref(res)
endfunction()








## `(<path>)-><string>`
## 
## retuns the extension of the specified path
## 
function(path_extension path)
  path("${path}")
  ans(path)
  get_filename_component(res "${path}" EXT)
  return_ref(res)  
endfunction()




# returns the name of the file without the directory
# if -we is specified the extensions is dropped
function(path_file_name path)
  set(args ${ARGN})
  list_extract_flag(args -we)
  ans(without_extension)
  if(without_extension)
    set(cmd NAME_WE)
  else()
    set(cmd NAME)
  endif() 
  path("${path}")
  ans(path)
  get_filename_component(res "${path}" ${cmd})
  return_ref(res)
endfunction()




## `(<subdir:<path>> <?path> )-><bool>`
##
## returns true iff subdir is or is below path
function(path_issubdir subdir path)
  set(path ${ARGN})
  path_qualify(path)
  path_qualify(subdir)
  string_starts_with("${subdir}" "${path}")
  return_ans()
endfunction()





## `(<path>)-><qualified path>` 
##
## returns the parent directory of the specified file or folder
## 
function(path_parent_dir path)
  path_qualify(path)
  get_filename_component(res "${path}" PATH)
  return_ref(res)
endfunction()




# returns the specified max n (all if n = 0)
# parent directories of path
function(path_parent_dirs path)
  set(continue 99999)
  if(ARGN )
    set(continue "${ARGN}")

    if("${continue}" EQUAL 0)
      set(continue 99999)
    endif()
  endif()

  path("${path}")
  ans(path)

  set(isrooted false)
  if("_${path}" MATCHES "^_[/]")
    set(isrooted true)
  endif()

  path_split("${path}")
  ans(parts)


  set(parent_dirs)
  while(true)
    if(NOT parts OR ${continue} LESS 1)
      break()
    endif()
    list_pop_back(parts)
    path_combine(${parts})
    ans(current)      

    if(isrooted)
      set(current "/${current}")
    endif()
    
    if("_${current}" STREQUAL "_")
      break()
    endif()
    list(APPEND parent_dirs "${current}")
    math(EXPR continue "${continue} - 1")

  endwhile()
  return_ref(parent_dirs)
endfunction()






## `(<path>)-><segment>` 
## 
## returns the name of the directory in which the specified file or folder resides
function(path_parent_dir_name)
  path("${ARGN}")
  ans(path)
  path_parent_dir("${path}")
  ans(path)
  path_component("${path}" --file-name-ext)
  return_ans()
endfunction()





## qualifies the specified variable as a path and sets it accordingly
macro(path_qualify __path_ref)
  path("${${__path_ref}}")
  ans(${__path_ref})
endmacro()





## `(<base_dir:<qualified path>> <~path>) -> <qualified path>`
##
## @todo realpath or abspath?
## qualfies a path using the specified base_dir
##
## if path is absolute (starts with / or under windows with <drive letter>:/) 
## it is returned as is
##
## if path starts with a '~' (tilde) the path is 
## qualfied by prepending the current home directory (on all OSs)
##
## is neither absolute nor starts with ~
## the path is relative and it is qualified 
## by prepending the specified <base dir>
function(path_qualify_from base_dir path)
  string(REPLACE \\ / path "${path}")
  get_filename_component(realpath "${path}" ABSOLUTE)
  
  ## windows absolute path
  if(WIN32 AND "_${path}" MATCHES "^_[a-zA-Z]:\\/")
    return_ref(realpath)
  endif()
   
   ## posix absolute path
  if("_${path}" MATCHES "^_\\/")
    return_ref(realpath)
  endif()


  ## home path
  if("_${path}" MATCHES "^_~\\/?(.*)")
    home_dir()
    ans(base_dir)
    set(path "${CMAKE_MATCH_1}")
  endif()

  set(path "${base_dir}/${path}")

  ## relative path
  get_filename_component(realpath "${path}" ABSOLUTE)
  
  return_ref(realpath)
endfunction()




# returns the path specified by path_rel relative to 
# path_base using parent dir path syntax (../../path/to/x)
# if necessary
# e.g. path_rel(c:/dir1/dir2 c:/dir1/dir3/dir4)
# will result in ../dir3/dir4
# returns nothing if transformation is not possible
function(path_relative path_base path_rel)
  set(args ${ARGN})

  path_qualify(path_base)
  path_qualify(path_rel)


  if("${path_base}" STREQUAL "${path_rel}")
    return(".")
  endif()

  path_split("${path_base}")
  ans(base_parts)

  path_split("${path_rel}")
  ans(rel_parts)

  set(result_base)

  set(first true)

  while(true)
    list_peek_front(base_parts)
    ans(current_base)
    list_peek_front(rel_parts)
    ans(current_rel)


    if(NOT "${current_base}" STREQUAL "${current_rel}")
      if(first)
        return_ref(path_rel)
      endif()
      break()
    endif()
    set(first false)

    path_combine("${result_base}" "${current_base}")
    ans(result_base)
    list_pop_front(base_parts)
    list_pop_front(rel_parts)
  endwhile()


  set(result_path)

  foreach(base_part ${base_parts})
    path_combine(${result_path} "..")
    ans(result_path)
  endforeach()


  path_combine(${result_path} ${rel_parts})
  ans(result_path)



  if("${result_path}" MATCHES "^\\/")
    string_substring("${result_path}" 1)
    ans(result_path)
  endif()

  return_ref(result_path)
endfunction()
# transforms a path to a path relative to base_dir
#function(path_relative base_dir path)
#  path("${base_dir}")
#  ans(base_dir)
#  path("${path}")
#  ans(path)
#  string_take(path "${base_dir}")
#  ans(match)
#
#  if(NOT match)
#    return_ref(path)
#    #message(FATAL_ERROR "${path} is  not relative to ${base_dir}")
#  endif()
#
#  if("${path}" MATCHES "^\\/")
#    string_substring("${path}" 1)
#    ans(path)
#  endif()
#
#
#  if(match AND NOT path)
#    set(path ".")
#  endif()
#
#  return_ref(path)
#endfunction()
#





  # splits the speicifed path into its directories and files
  # e.g. c:/dir1/dir2/file.ext -> ['c:','dir1','dir2','file.ext'] 
  function(path_split path)
    if("_${path}" MATCHES "^_[\\/]")
      string_substring("${path}" 1)
      ans(path)
    endif()
    string_split("${path}" "[/]")
    ans(parts)

    return_ref(parts)
  endfunction()




## returns a temporary path in the specified directory
## if no directory is given the global temp_dir is used isntead
function(path_temp)
  set(args ${ARGN})

  if("${args}_" STREQUAL "_")
    cmakepp_config(temp_dir)
    ans(tmp_dir)
    set(args "${tmp_dir}")
  else()
    path("${args}")
    ans(args)
  endif()

  path_vary("${args}/mktemp")
  ans(path)

  return_ref(path)
endfunction()





# writes the path the map creating submaps for every directory

function(path_to_map map path)
  
  path_split("${path}")
  ans(path_parts)

  set(current ${map})
  while(true)
    list_pop_front(path_parts)
    ans(current_part)


    
    map_tryget(${current} "${current_part}")
    ans(current_map)

    if(NOT path_parts)
      if(NOT current_map)
      map_set(${current} "${current_part}" "${path}")
      endif()
      return()
    endif()

    is_map("${current_map}")
    ans(ismap)

    if(NOT ismap)
      map_new()
      ans(current_map)
    endif()

    map_set(${current} "${current_part}" ${current_map})
    set(current ${current_map})
  endwhile()
endfunction()




## `(<path>)-><qualified path>`
##
## varies the specified path until it does not exist
## this is done  by inserting a random string into the path and doing so until 
## a path is vound whic does not exist
function(path_vary path)
  path_qualify(path)
  get_filename_component(ext "${path}" EXT)
  get_filename_component(name "${path}" NAME_WE)
  get_filename_component(base "${path}" PATH)
  set(rnd)
  while(true)
    set(path "${base}/${name}${rnd}${ext}")

    if(NOT EXISTS "${path}")
      return("${path}")
    endif()


    ## alternatively count up
    string(RANDOM rnd)
    set(rnd "_${rnd}")

  endwhile()
endfunction()




## `(<path>)-><bool>`
## 
## unlinks the specified link without removing the links content.
function(unlink)
  wrap_platform_specific_function(unlink)
  unlink(${ARGN})
  return_ans()
endfunction()



function(unlink_Windows symlink)
  path_qualify(symlink)
  string(REPLACE "/" "\\" symlink "${symlink}") 
  win32_cmd_lean("/C" "rmdir" "${symlink}")
  ans_extract(res)
  if(res)
    return(false)
  endif()
  return(true)
endfunction()


function(unlink_Linux symlink)
  path_qualify(symlink)
  if("${symlink}" MATCHES "(.*)\\/$")
    set(symlink "${CMAKE_MATCH_1}")
  endif()
  execute_process(COMMAND "unlink" "${symlink}" RESULT_VARIABLE res)
  if(res)
    return(false)
  endif()

  return(true)
endfunction()






  function(cmake_deserialize serialized)
     fwrite_temp("" ".cmake")
  ans(tmp)

    eval("
        function(cmake_deserialize serialized)
            file(WRITE \"${tmp}\" \"\${serialized}\")
            cmake_deserialize_file(\"${tmp}\")
            set(__ans \${__ans} PARENT_SCOPE)
        endfunction()
    ")
    cmake_deserialize("${serialized}")
    return_ans()
  endfunction()





function(cmake_deserialize_file file)
  if(NOT EXISTS "${file}")
    return()
  endif()
   address_new()
   ans(result)
   include("${file}")
   address_get(${result})
   return_ans()
endfunction()





function(cmake_read path)
  path_qualify(path)
  cmake_deserialize_file("${path}")
  return_ans()
endfunction()





  function(cmake_serialize)
      function(cmake_ref_format)
        set(prop)
        if(ARGN)
          set(prop ".${ARGN}")
        endif()
        set(__ans ":\${ref}${prop}" PARENT_SCOPE)
      endfunction()

     # define callbacks for building result
    function(cmake_obj_begin)
      map_tryget(${context} ${node})
      ans(ref)
      map_push_back(${context} refstack ${ref})
      map_append_string(${context} qm 
"math(EXPR ref \"\${base} + ${ref}\")
")
    endfunction()

    function(cmake_obj_end)
      map_pop_back(${context} refstack)
      map_peek_back(${context} refstack)
      ans(ref)

      map_append_string(${context} qm 
"math(EXPR ref \"\${base} + ${ref}\")
")
    endfunction()
    
    function(cmake_obj_keyvalue_begin)
      cmake_ref_format()
      ans(keystring)
      cmake_ref_format(${map_element_key})
      ans(refstring)
      
      map_append_string(${context} qm 
"set_property(GLOBAL APPEND PROPERTY \"${keystring}.__keys__\" \"${map_element_key}\")
set_property(GLOBAL PROPERTY \"${refstring}\")
")
    endfunction()

    function(cmake_literal)
      cmake_ref_format(${map_element_key})
      ans(refstring)
      cmake_string_escape("${node}")
      ans(node)
      map_append_string(${context} qm 
"set_property(GLOBAL APPEND PROPERTY \"${refstring}\" \"${node}\")
")
      return()
    endfunction()

    function(cmake_unvisited_reference)
      map_tryget(${context} ref_count)
      ans(ref_count)
      math(EXPR ref "${ref_count} + 1")
      map_set_hidden(${context} ref_count ${ref})
      map_set_hidden(${context} ${node} ${ref})

      cmake_ref_format(${map_element_key})
      ans(refstring)

      map_append_string(${context} qm
"math(EXPR value \"\${base} + ${ref}\")
set_property(GLOBAL PROPERTY \":\${value}.__type__\" \"map\")
set_property(GLOBAL APPEND PROPERTY \"${refstring}\" \":\${value}\")
")
    endfunction()
    function(cmake_visited_reference)
map_tryget(${context} "${node}")
ans(ref)

  cmake_ref_format(${map_element_key})
  ans(refstring)
map_append_string(${context} qm
"#revisited node
math(EXPR value \"\${base} + ${ref}\")
set_property(GLOBAL APPEND PROPERTY \"${refstring}\" \":\${value}\")
# end of revisited node
")


    endfunction()
     map()
      kv(value              cmake_literal)
      kv(map_begin          cmake_obj_begin)
      kv(map_end            cmake_obj_end)
      kv(map_element_begin  cmake_obj_keyvalue_begin)
      kv(visited_reference  cmake_visited_reference)
      kv(unvisited_reference  cmake_unvisited_reference)
    end()
    ans(cmake_cbs)
    function_import_table(${cmake_cbs} cmake_callback)

    # function definition
    function(cmake_serialize)        
      map_new()
      ans(context)
      map_set(${context} refstack 0)
      map_set(${context} ref_count 0)
  
      dfs_callback(cmake_callback ${ARGN})
      map_tryget(${context} qm)
      ans(res)
      map_tryget(${context} ref_count)
      ans(ref_count)

      set(res "#cmake/1.0
get_property(base GLOBAL PROPERTY \":0\")
set(ref \${base})
${res}math(EXPR base \"\${base} + ${ref_count} + 1\")
set_property(GLOBAL PROPERTY \":0\" \${base})
")

      return_ref(res)  
    endfunction()
    #delegate
    cmake_serialize(${ARGN})
    return_ans()
  endfunction()






function(cmake_write path )
    cmake_serialize(${ARGN})
    ans(serialized)
    fwrite("${path}" "${serialized}")
    return_ans()
endfunction()




# deserializes a csv string 
# currently expects the first line to be the column headers
# rows are separated by \n or \r\n
# every value is delimited by double quoutes ""
function(csv_deserialize csv) 
  set(args ${ARGN})
  list_extract_flag(args --headers)
  ans(first_line_headers)
  string(REPLACE "\r" "" csv "${csv}")

  string_split("${csv}" "\n")
  ans(lines)
  string(STRIP "${lines}" lines)

  set(res)
  set(headers)
  set(first true)
  set(i 0)
  foreach(line ${lines})
    map_new()
    ans(current_line)
    set(current_headers ${headers})
    while(true)
      string_take_delimited(line)
      ans(val)
      if("${line}_" STREQUAL "_")
        break()
      endif()

      string_take(line ",")
      ans(comma)
        
      if(first)
        if(first_line_headers)
          list(APPEND headers "${val}")
        else()
          list(APPEND headers ${i})            
        endif()
        math(EXPR i "${i} + 1")
      else()
        list_pop_front(current_headers)
        ans(current_header)
        map_set(${current_line} "${current_header}" "${val}")
      endif()

    endwhile()
    if(NOT first)
      list(APPEND res ${current_line})
    elseif(NOT  first_line_headers)
      list(APPEND res ${current_line})
    endif()
    if(first)        
      set(first false)
    endif()

  endforeach()
  return_ref(res)
endfunction()






  function(csv_serialize )
    set(args ${ARGN})
    message(FATAL_ERROR)

  endfunction()





function(json)
# define callbacks for building result
  function(json_obj_begin)
    map_append_string(${context} json "{")
  endfunction()
  function(json_obj_end)
    map_append_string(${context} json "}")
  endfunction()
  function(json_array_begin)
    map_append_string(${context} json "[")
  endfunction()
  function(json_array_end)
    map_append_string(${context} json "]")
  endfunction()
  function(json_obj_keyvalue_begin)
    cmake_string_to_json("${map_element_key}")
    ans(map_element_key)
    map_append_string(${context} json "${map_element_key}:")
  endfunction()

  function(json_obj_keyvalue_end)
    math(EXPR comma "${map_length} - ${map_element_index} -1 ")
    if(comma)
      map_append_string(${context} json ",")
    endif()
  endfunction()

  function(json_array_element_end)
    math(EXPR comma "${list_length} - ${list_element_index} -1 ")
    if(comma)
      map_append_string(${context} json ",")
    endif()
  endfunction()
  function(json_literal)
    if(NOT content_length)
      map_append_string(${context} json "null")
    elseif("_${node}" MATCHES "^_((([1-9][0-9]*)([.][0-9]+([eE][+-]?[0-9]+)?)?)|true|false)$")
      map_append_string(${context} json "${node}")
    else()
      cmake_string_to_json("${node}")
      ans(node)
      map_append_string(${context} json "${node}")
    endif()
    return()

  endfunction()

   map()
    kv(value              json_literal)
    kv(map_begin          json_obj_begin)
    kv(map_end            json_obj_end)
    kv(list_begin         json_array_begin)
    kv(list_end           json_array_end)
    kv(map_element_begin  json_obj_keyvalue_begin)
    kv(map_element_end    json_obj_keyvalue_end)
    kv(list_element_end   json_array_element_end)
  end()
  ans(json_cbs)
  function_import_table(${json_cbs} json_callback)

  # function definition
  function(json)        
    map_new()
    ans(context)
    dfs_callback(json_callback ${ARGN})
    map_tryget(${context} json)
    return_ans()  
  endfunction()
  #delegate
  json(${ARGN})
  return_ans()
endfunction()




function(json2 input)
  
  json2_definition()
  ans(lang)
  language_initialize(${lang})
  address_set(json2_language_definition "${lang}")
  function(json2 input) 
    checksum_string("${input}")   
    ans(ck)
    file_cache_return_hit("${ck}")
    address_get(json2_language_definition)
    ans(lang)
    map_new()
    ans(ctx)
    map_set(${ctx} input "${input}")
    map_set(${ctx} def "json")
    obj_setprototype(${ctx} "${lang}")

    #lang2(output json2 input "${input}" def "json")

    lang(output ${ctx})
    ans(res)
    file_cache_update("${ck}" ${res})
    return_ref(res)
  endfunction()
  json2("${input}")
  return_ans()
endfunction()




function(json2_definition)
map()
 key("name")
  val("json2")
 key("phases")
 map()
  key("name")
   val("parse")
  key("function")
   val("parse_string\(/0\ /1\ /2\ /3\ /4\)")
  key("input")
   val("input_ref")
   val("def")
   val("definitions")
   val("parsers")
   val("global")
  key("output")
   val("output")
 end()
 map()
  key("name")
   val("create\ input\ ref")
  key("function")
   val("address_set_new\(/0\)")
  key("input")
   val("input")
  key("output")
   val("input_ref")
 end()
 key("parsers")
 map()
  key("regex")
   val("parse_regex")
  key("match")
   val("parse_match")
  key("sequence")
   val("parse_sequence")
  key("any")
   val("parse_any")
  key("many")
   val("parse_many")
  key("object")
   val("parse_object")
 end()
 key("definitions")
 map()
  key("json")
  map()
   key("parser")
    val("any")
   key("any")
    val("value")
  end()
  key("value")
  map()
   key("parser")
    val("any")
   key("any")
    val("string")
    val("number")
    val("null")
    val("boolean")
    val("object")
    val("array")
  end()
  key("object")
  map()
   key("parser")
    val("object")
   key("begin")
    val("brace_open")
   key("keyvalue")
    val("keyvalue")
   key("end")
    val("brace_close")
   key("separator")
    val("comma")
  end()
  key("keyvalue")
  map()
   key("parser")
    val("sequence")
   key("sequence")
   map()
    key("key")
     val("string")
    key("colon")
     val("/colon")
    key("value")
     val("value")
   end()
  end()
  key("array")
  map()
   key("parser")
    val("many")
   key("begin")
    val("bracket_open")
   key("element")
    val("value")
   key("separator")
    val("comma")
   key("end")
    val("bracket_close")
  end()
  key("string")
  map()
   key("parser")
    val("regex")
   key("regex")
   regex_escaped_string(\" \")
   ans(regex)
   val("${regex}")
    #val("\"\(\([\^\\\"]|\\\\|\(\\\\([\"tnr]\)\)\)*\)\"")
   #key("replace")
   # val("\\\\1")
   key("transform")
    val("json_string_ref_to_cmake")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
  key("number")
  map()
   key("parser")
    val("regex")
   key("regex")
    val("0|[1-9][0-9]*")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
  key("boolean")
  map()
   key("parser")
    val("regex")
   key("regex")
    val("(true|false)")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
  key("null")
  map()
   key("parser")
    val("regex")
   key("regex")
    val("(null)")
   key("replace")
    val("")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
  key("whitespace")
  map()
   key("parser")
    val("regex")
   key("regex")
    val("[\ \n\r\t]+")
  end()
  key("colon")
  map()
   key("parser")
    val("match")
   key("search")
    val(":")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
  key("comma")
  map()
   key("parser")
    val("match")
   key("search")
    val(",")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
  key("brace_open")
  map()
   key("parser")
    val("match")
   key("search")
    val("{")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
  key("brace_close")
  map()
   key("parser")
    val("match")
   key("search")
    val("}")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
  key("bracket_open")
  map()
   key("parser")
    val("match")
   key("search")
    val("[")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
  key("bracket_close")
  map()
   key("parser")
    val("match")
   key("search")
    val("]")
   key("ignore_regex")
    val("[\ \n\r\t]+")
  end()
 end()
end()
return_ans()
endfunction()




function(json3_cached)
  define_cache_function(json3_cached json3)
  json3_cached("${ARGN}")
  return_ans()
endfunction()
## 
##
## fast json parser
function(json3 input)
  string_encode_list("${input}")
  ans(input)
  string_codes()
  regex_json()
  string(REGEX MATCHALL "${regex_json_literal}" literals "${input}")
  string(REGEX REPLACE "${regex_json_literal}" "${free_token}" input "${input}" )
  string(REGEX REPLACE "(.)" "\\1;" tokens "${input}")
  address_new()
  ans(base)
  set(ref ${base})
  set(ref_stack)
  #address_new()
  #ans(cmake_serialized)
  while(true)
    list(LENGTH tokens len)
    if(NOT len)
      break()
    endif()
    list(GET tokens 0 token)
    list(REMOVE_AT tokens 0)
    if("${token}" STREQUAL "{")
      list(INSERT ref_stack 0 ${ref})
      map_new()
      ans(value)
      set_property(GLOBAL APPEND_STRING PROPERTY "${ref}" "${value}")
      set(ref ${value})
    elseif("${token}" STREQUAL "}")
      if("${ref}" MATCHES ".[0-9]+\\..+")
        list(GET ref_stack 0 ref)
        list(REMOVE_AT ref_stack 0)
      endif()
      list(GET ref_stack 0 ref)
      list(REMOVE_AT ref_stack 0)
    elseif("${token}" STREQUAL "${free_token}")
      list(GET literals 0 value)
      list(REMOVE_AT literals 0)
      list(GET tokens 0 next_token)
      if("${next_token}" STREQUAL ":" AND NOT "${value}" MATCHES "\".*\"")
        message(FATAL_ERROR "expected key to be a string instead got '${value}'")
      elseif("${next_token}" STREQUAL ":")
        list(REMOVE_AT tokens 0)
        json_string_to_cmake("${value}")
        ans(key)
        list(INSERT ref_stack 0 ${ref})
        set_property(GLOBAL APPEND PROPERTY "${ref}" "${key}")
        set(ref "${ref}.${key}")
      else()
        if("${value}" MATCHES \".*\")
          json_string_to_cmake("${value}")
          ans(value)
          string_decode_list("${value}")
          ans(value)
        elseif("${value}" STREQUAL "null")
          set(value)
        endif()
        set_property(GLOBAL APPEND_STRING PROPERTY "${ref}" "${value}")
      endif()
    elseif("${token}" STREQUAL ":")
      messaGE(FATAL_ERROR "unexpected ':'")
    elseif("${token}" STREQUAL ",")
      if("${ref}" MATCHES ".[0-9]+\\..+")
        list(GET ref_stack 0 ref)
        list(REMOVE_AT ref_stack 0)
      else()
        set_property(GLOBAL APPEND_STRING PROPERTY "${ref}" ";")
      endif()
    elseif("${token}" STREQUAL "${bracket_open_code}")  
      list(INSERT ref_stack 0 ${ref})
      address_new()
      ans(ref)
    elseif("${token}" STREQUAL "${bracket_close_code}")  
      get_property(values GLOBAL PROPERTY "${ref}")
      list(GET ref_stack 0 ref)
      list(REMOVE_AT ref_stack 0)
      set_property(GLOBAL APPEND_STRING PROPERTY "${ref}" "${values}")
    endif()
  endwhile()
  address_get(${base})
  return_ans()
endfunction()







function(json4 input)
  string_encode_list("${input}")
  ans(input)
  regex_json()
  string(REGEX MATCHALL "${regex_json_token}" tokens "${input}")
  string(REGEX REPLACE "${regex_json_token}" "" input "${input}" )
  if(NOT "${input}_" STREQUAL "_")
    message(FATAL_ERROR "invalid json - the following could no be tokenized : '${input}'")
  endif()

  map_new()
  ans(result)
  map_set("${result}" value)
  set(current_key value)
  set(is_array object)
  set(current_ref "${result}")
  set(ref_stack)
  set(key_stack)
  set(is_array_stack)
  while(true)
    list(LENGTH tokens length)
    if(NOT length)
      break()
    endif()
    list(GET tokens 0 token)
    list(REMOVE_AT tokens 0)


    if("${token}" MATCHES "^\"(.*)\"$")
      json_string_to_cmake("${token}")
      string_decode_bracket("${__ans}") ## semicolons will stay encoded...
      set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" "${__ans}")
    elseif("${token}" MATCHES "^${regex_json_number_token}$")
      ## todo validate number correclty
      set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" "${token}")
    elseif("${token}" MATCHES "^${regex_json_bool_token}$")
      set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" "${token}")
    elseif("${token}" MATCHES "^${regex_json_null_token}$")
      ## do nothing because json null is empty string in cmake
    elseif("${token}" MATCHES "^(${regex_json_array_begin_token})|(${regex_json_object_begin_token})$")
      list(INSERT ref_stack 0 "${current_ref}")
      list(INSERT key_stack 0 "${current_key}")
      list(INSERT is_array_stack 0 "${is_array}")
      if("${token}" STREQUAL "${regex_json_array_begin_token}")
        set(is_array true)
      else() ## ${token} STREQUAL "${regex-json_object_begin_token}"
        map_new()
        ans(new_ref)
        set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" "${new_ref}")
        set(current_key "${free_token}")
        set(current_ref "${new_ref}")
        set(is_array false)
      endif()
    elseif("${token}" MATCHES "^(${regex_json_array_end_token})|(${regex_json_object_end_token})$")
      list(GET ref_stack 0 current_ref)
      list(REMOVE_AT ref_stack 0)
      list(GET key_stack 0 current_key)
      list(REMOVE_AT key_stack 0)
      list(GET is_array_stack 0 is_array)
      list(REMOVE_AT is_array_stack 0)
    elseif("${token}" MATCHES "^${regex_json_separator_token}$")
      if(is_array)
        set_property(GLOBAL APPEND_STRING PROPERTY "${current_ref}.${current_key}" ";")
      else()
        set(current_key "${free_token}")
      endif()
    elseif("${token}" MATCHES "^${regex_json_keyvalue_token}$")
      if("${current_key}" STREQUAL "${free_token}")
        get_property(current_key GLOBAL PROPERTY "${current_ref}.${free_token}")
        set_property(GLOBAL PROPERTY "${current_ref}.${free_token}")
        map_set("${current_ref}" "${current_key}")
      endif()
    #elseif("${token}" MATCHES "^${regex_json_whitespace_token}$") # ignored
    # else()  #error
    endif()



  endwhile()
  map_tryget("${result}" value)
  return_ans()

endfunction()




## `(<json code>)->{}`
##
## deserializes the specified json code. In combination with json there are a few things
## that need mention:
## * semicolons.  If you use semicolons in json then they will be deserialized as
##   ASCII 31 (Unit Separator) which allows cmake to know the difference to the semicolons in a list
##   if you want semicolons to appear in cmake then use a json array. You can always use `string_decode_semicolon()`
##   to obtain the string as it was in json
##   eg. `[1,2,3] => 1;2;3`  `"1;2;3" => 1${semicolon_code}2${semicolon_code}3`
## 
function(json_deserialize json)
  json4("${json}")
  return_ans()
endfunction()




# function to escape json
function(json_escape value)
	string(REGEX REPLACE "\\\\" "\\\\\\\\" value "${value}")
	string(REGEX REPLACE "\\\"" "\\\\\"" value "${value}")
	string(REGEX REPLACE "\n" "\\\\n" value "${value}")
	string(REGEX REPLACE "\r" "\\\\r" value "${value}")
	string(REGEX REPLACE "\t" "\\\\t" value "${value}")
	string(REGEX REPLACE "\\$" "\\\\$" value "${value}")	
	string(REGEX REPLACE ";" "\\\\\\\\;" value "${value}")
	return_ref(value)
endfunction()





  ## quickly extracts string properties values from a json string
  ## useful for large json files with unique property keys
  function(json_extract_string_value key data)
    regex_escaped_string("\"" "\"") 
    ans(regex)

    set(key_value_regex "\"${key}\" *: ${regex}")
    string(REGEX MATCHALL  "${key_value_regex}" matches "${data}")
    set(values)
    foreach(match ${matches})
      string(REGEX REPLACE "${key_value_regex}" "\\1" match "${match}")
      list(APPEND values "${match}")
    endforeach() 
    return_ref(values)
  endfunction()




function(json_format_tokens result tokens)
	set(spacing "  ")
	set(level 0)
	set(indentation "")
	macro(set_indent)
		set(indentation)
		if("${level}" GREATER 0)
		math(EXPR range "${level} - 1")
		foreach(i RANGE "${range}")
			set(indentation "${indentation}${spacing}")
		endforeach()
		endif()
	endmacro()
	macro(increase_indent)
		math(EXPR level "${level} + 1")
		set_indent()
	endmacro()


	macro(decrease_indent)
		math(EXPR level "${level} - 1")
		set_indent()
	endmacro()
	set_indent()

	set(indented "${indentation}")
	foreach(token ${tokens})		
		if("${token}" STREQUAL "{")
			increase_indent()
			set(indented "${indented}{\n${indentation}")
		elseif("${token}" STREQUAL "<")
			increase_indent()
			set(indented "${indented}[\n${indentation}")
		elseif("${token}" STREQUAL ",")
			set(indented "${indented},\n${indentation}")
		elseif("${token}" STREQUAL "}")
			decrease_indent()
			set(indented "${indented}\n${indentation}}")
		elseif("${token}" STREQUAL ">")
			decrease_indent()
			set(indented "${indented}\n${indentation}]")
		elseif("${token}" STREQUAL ":")
			set(indented "${indented} : ")
		else()
			if(NOT  "${token}" MATCHES "^\".*")
				set(indented "${indented};")
			endif()

			json_escape( "${token}")
			ans(token)
			set(indented "${indented}${token}")
		endif()



	endforeach()
	return_value("${indented}")
endfunction()





function(json_indented)
  # define callbacks for building result
  function(json_obj_begin_indented)
   # message(PUSH_AFTER "json_obj_begin_indented(${ARGN})")
    map_tryget(${context} indentation)
    ans(indentation)
    map_append_string(${context} json "{\n")
    map_append_string(${context} indentation " ")
  endfunction()
  function(json_obj_end_indented)
    #message(POP "json_obj_end_indented(${ARGN})")
    map_tryget(${context} indentation)
    ans(indentation)
    string(SUBSTRING "${indentation}" 1 -1 indentation)
    map_set(${context} indentation "${indentation}")
    map_append_string(${context} json "${indentation}}")

  endfunction()
  function(json_array_begin_indented)
    #message(PUSH_AFTER "json_array_begin_indented(${ARGN}) ${context}")
    map_tryget(${context} indentation)
    ans(indentation)
    map_append_string(${context} json "[\n")
    map_append_string(${context} indentation " ")
    
  endfunction()
  function(json_array_end_indented)
   # message(POP "json_array_end_indented(${ARGN}) ${context}")
    map_tryget(${context} indentation)
    ans(indentation)
    string(SUBSTRING "${indentation}" 1 -1 indentation)
    map_set(${context} indentation "${indentation}")
    map_append_string(${context} json "${indentation}]")
  endfunction()
  function(json_obj_keyvalue_begin_indented)
   # message("json_obj_keyvalue_begin_indented(${key} ${ARGN}) ${context}")
    map_tryget(${context} indentation)
    ans(indentation)
    map_append_string(${context} json "${indentation}\"${map_element_key}\":")
  endfunction()

  function(json_obj_keyvalue_end_indented)
    #message("json_obj_keyvalue_end_indented(${ARGN}) ${context}")
    math(EXPR comma "${map_length} - ${map_element_index} -1 ")
    if(comma)
      map_append_string(${context} json ",")
    endif()
    
    map_append_string(${context} json "\n")
  endfunction()

  function(json_array_element_begin_indented)
   # message("json_array_element_begin_indented(${ARGN}) ${context}")
    map_tryget(${context} indentation)
    ans(indentation)
    map_append_string(${context} json "${indentation}")
  endfunction()
  function(json_array_element_end_indented)
   #message("json_array_element_end_indented(${ARGN}) ${context}")
    math(EXPR comma "${list_length} - ${list_element_index} -1 ")
    if(comma)
      map_append_string(${context} json ",")
    endif()
    map_append_string(${context} json "\n")
  endfunction()
  function(json_literal_indented)
    if(NOT content_length)
      map_append_string(${context} json "null")
    elseif("_${node}" MATCHES "^_(0|(([1-9][0-9]*)([.][0-9]+([eE][+-]?[0-9]+)?)?)|(true)|(false))$")
      map_append_string(${context} json "${node}")
    else()
      cmake_string_to_json("${node}")
      ans(node)
      map_append_string(${context} json "${node}")
    endif()
    return()
  endfunction()

   map()
    kv(value              json_literal_indented)
    kv(map_begin          json_obj_begin_indented)
    kv(map_end            json_obj_end_indented)
    kv(list_begin         json_array_begin_indented)
    kv(list_end           json_array_end_indented)
    kv(map_element_begin  json_obj_keyvalue_begin_indented)
    kv(map_element_end    json_obj_keyvalue_end_indented)
    kv(list_element_begin json_array_element_begin_indented)
    kv(list_element_end   json_array_element_end_indented)
  end()
  ans(json_cbs)
  function_import_table(${json_cbs} json_indented_callback)

  # function definition
  function(json_indented)        
    map_new()
    ans(context)
    dfs_callback(json_indented_callback ${ARGN})
    map_tryget(${context} json)
    return_ans()  
  endfunction()
  #delegate
  json_indented(${ARGN})
  return_ans()
endfunction()




function(json_print)
  json_indented(${ARGN})
  ans(res)
  _message("${res}")
endfunction()




# reads a json file from the specified location
# the location may be relative (see explanantion of path() function)
# returns a map or nothing if reading fails 
function(json_read file)
    path("${file}")
    ans(file)
    if(NOT EXISTS "${file}")
      return()
    endif()
    checksum_file("${file}")
    ans(cache_key)
    file_cache_return_hit("${cache_key}")

    file(READ "${file}" data)
    json_deserialize("${data}")
    ans(data)

    file_cache_update("${cache_key}" "${data}")

    return_ref(data)
endfunction()





  function(json_string_to_cmake str)
    # remove trailing and leading quotation marks
    if("${str}" MATCHES "\"(.*)\"")
      set(str "${CMAKE_MATCH_1}")
      ## escape semicolon
      string(REPLACE "\\\\;" ";" str "${CMAKE_MATCH_1}")
    endif()

    string(ASCII 8 char)
    string(REPLACE  "\\b" "${char}" str "${str}")
    string(ASCII 12 char)
    string(REPLACE  "\\f" "${char}" str "${str}")

    
    string(REPLACE "\\n" "\n" str "${str}")
    string(REPLACE "\\t" "\t" str "${str}")
    string(REPLACE "\\t" "\t" str "${str}")
    string(REPLACE "\\r" "\r" str "${str}")
    string(REPLACE "\\\"" "\"" str "${str}")

    string(REPLACE "\\\\" "\\" str "${str}")

    return_ref(str)
      
  endfunction()
  # converts the json-string & to a cmake string
  function(json_string_ref_to_cmake __json_string_ref_to_cmake_ref)
    json_string_to_cmake("${${__json_string_ref_to_cmake_ref}}")
    return_ans()
      
  endfunction()




function(json_tokenize result json)

	set(regex "(\\{|\\}|:|,|\\[|\\]|\"(\\\\.|[^\"])*\")")
	string(REGEX MATCHALL "${regex}" matches "${json}")


	# replace brackets with angular brackets because
	# normal brackes are not handled properly by cmake
	string(REPLACE  ";[;" ";<;" matches "${matches}")
	string(REPLACE ";];" ";>;" matches "${matches}")
	string(REPLACE "[" "†" matches "${matches}")
	string(REPLACE "]" "‡" matches "${matches}")

	set(tokens)
	foreach(match ${matches})
		string_char_at( 0 "${match}")
		ans(char)
		if("${char}" STREQUAL "[")
			string_char_at( -2 "${match}")
			ans(char)
			if(NOT "${char}" STREQUAL "]")
				message(FATAL_ERROR "json syntax error: no closing ']' instead: '${char}' ")
			endif()
			string(LENGTH "${match}" len)
			math(EXPR len "${len} - 2")
			string(SUBSTRING ${match} 1 ${len} array_values)
			set(tokens ${tokens} "<")
			foreach(submatch ${array_values})
				set(tokens ${tokens} ${submatch} )
			endforeach()
			set(tokens ${tokens} ">")
		else()
			set(tokens ${tokens} ${match})
		endif()
	endforeach()

	set(${result} ${tokens} PARENT_SCOPE)
endfunction()




# write the specified object reference to the specified file
## todo rename to fwrite_json(path data)
  function(json_write file obj)
    path("${file}")
    ans(file)
    json_indented(${obj})
    ans(data)
    file(WRITE "${file}" "${data}")
    return()
  endfunction()





function(qm_deserialize quick_map_string)
  set_ans("")
  eval("${quick_map_string}")
  ans(res)
  address_get($"{res}")
#  map_tryget(${res} data)
  return_ans()
endfunction()








# deserializes the specified file
function(qm_deserialize_file quick_map_file)
  if(NOT EXISTS "${quick_map_file}")
    return()
  endif()
  include(${quick_map_file})
  ans(res)
  address_get(${res})
  return_ans()
endfunction()




function(qm_print)
  qm_serialize(${ARGN})
  ans(res)

  message("${res}")
  return()
endfunction()




# reads the qualifies and reads the specified <unqualified path>
# returns a <map>
function(qm_read path)
  path("${path}")
  ans(path)

  qm_deserialize_file("${path}")
  return_ans()
  
endfunction()





function(qm_serialize)
  # define callbacks for building result
  function(qm_obj_begin_indented)
   # message(PUSH_AFTER "qm_obj_begin_indented(${ARGN})")
    map_tryget(${context} indentation)
    ans(indentation)
    map_append_string(${context} qm "${indentation}map()\n")
    map_append_string(${context} indentation " ")
  endfunction()
  function(qm_obj_end_indented)
    #message(POP "qm_obj_end_indented(${ARGN})")
    map_tryget(${context} indentation)
    ans(indentation)
    string(SUBSTRING "${indentation}" 1 -1 indentation)
    map_set(${context} indentation "${indentation}")
    map_append_string(${context} qm "${indentation}end()\n")

  endfunction()

  function(qm_obj_keyvalue_begin_indented)
   # message("qm_obj_keyvalue_begin_indented(${key} ${ARGN}) ${context}")
    map_tryget(${context} indentation)
    ans(indentation)
    map_append_string(${context} qm "${indentation}key(\"${map_element_key}\")\n")
  endfunction()

  function(qm_literal_indented)
    map_tryget(${context} indentation)
    ans(indentation)
    
    cmake_string_escape("${node}")
    ans(node)
    map_append_string(${context} qm "${indentation} val(\"${node}\")\n")
    
    return()
  endfunction()


   map()
    kv(value              qm_literal_indented)
    kv(map_begin          qm_obj_begin_indented)
    kv(map_end            qm_obj_end_indented)
    kv(map_element_begin  qm_obj_keyvalue_begin_indented)
  end()
  ans(qm_cbs)
  function_import_table(${qm_cbs} qm_indented_callback)

  # function definition
  function(qm_serialize)        
    map_new()
    ans(context)
    map_set(${context} qm "#qm/1.0\nref()\n")
    #map_new()
    #ans(data)
    #map_set(${data} data "${ARGN}")
    dfs_callback(qm_indented_callback ${ARGN})
    map_tryget(${context} qm)
    ans(res)
    set(res "${res}end()\n")
    return_ref(res)  
  endfunction()
  #delegate
  qm_serialize(${ARGN})
  return_ans()
endfunction()



function(qm_serialize_unindented)
  # define callbacks for building result
  function(qm_obj_begin_unindented)
    map_append_string(${context} qm "map()\n")
  endfunction()
  function(qm_obj_end_unindented)
    map_append_string(${context} qm "end()\n")

  endfunction()

  function(qm_obj_keyvalue_begin_unindented)
    map_append_string(${context} qm "key(\"${map_element_key}\")\n")
  endfunction()

  function(qm_literal_unindented)
    cmake_string_escape("${node}")
    ans(node)
    map_append_string(${context} qm "val(\"${node}\")\n")
    return()
  endfunction()


   map()
    kv(value              qm_literal_unindented)
    kv(map_begin          qm_obj_begin_unindented)
    kv(map_end            qm_obj_end_unindented)
    kv(map_element_begin  qm_obj_keyvalue_begin_unindented)
  end()
  ans(qm_cbs)
  function_import_table(${qm_cbs} qm_unindented_callback)

  # function definition
  function(qm_serialize_unindented)        
    map_new()
    ans(context)
    map_set(${context} qm "#qm/1.0\nref()\n")
    #map_new()
    #ans(data)
    #map_set(${data} data "${ARGN}")
    dfs_callback(qm_unindented_callback ${ARGN})
    map_tryget(${context} qm)
    ans(res)
    set(res "${res}end()\n")
    return_ref(res)  
  endfunction()
  #delegate
  qm_serialize_unindented(${ARGN})
  return_ans()
endfunction()





# writes the specified values to path as a quickmap file
# path is an <unqualified file>
# returns the <qualified path> were values were written to
function(qm_write path )
  path("${path}")
  ans(path)

  qm_serialize(${ARGN})
  ans(res)
  fwrite("${path}" "${res}")
  return_ref(path)
endfunction()




# parses a table as is output by win32 commands like tasklist
# the format is
# header1 header2 header3
# ======= ======= =======
# val1    val2    val3
# val4    val5    val6
# not that the = below the header is used as the column width and must be the max length of any value in 
# column including the header
# returns a list of <row> where row is a map and the headers are the keys   (values are trimmed from whitespace)
# the example above results in 
# {
#   "header1":"val1",
#   "header2":"val2",
#   "header3":"val3"
# }
#
function(table_deserialize input)
  string_lines("${input}")
  ans(lines)
  list_pop_front(lines)
  ans(firstline)  
  list_pop_front(lines)    
  ans(secondline)
  list_pop_front(lines)    
  ans(thirdline)

  string(REPLACE "=" "." line_match "${thirdline}")
  string_split("${line_match}" " ")
  ans(parts)
  list(LENGTH parts cols) 
  set(linematch)
  set(first true)
  foreach(part ${parts})
    if(first)
      set(first false)
    else()
      set(linematch "${linematch} ")
    endif()
    set(linematch "${linematch}(${part})")
  endforeach()

  set(headers __empty) ## empty is there to buffer so that headers can be index 1 based instead of 0 based
  foreach(idx RANGE 1 ${cols})
    string(REGEX REPLACE "${linematch}" "\\${idx}" header "${secondline}")
    string(STRIP "${header}" header)
    list(APPEND headers ${header})
  endforeach()



  set(result)
  foreach(line ${lines})
    map_new()
    ans(l)
    foreach(idx RANGE 1 ${cols})
      string(REGEX REPLACE "${linematch}" "\\${idx}" col "${line}")
      string(STRIP "${col}" col)
      list_get(headers ${idx})
      ans(header)
      map_set(${l} "${header}" "${col}")        
    endforeach()
    list(APPEND result ${i})
  endforeach()

  return_ref(result)
endfunction()





# not finished
function(table_serialize)  
  objs(${ARGN})  
  ans(lines)


  map_new()
  ans(column_layout)

  set(allkeys)

  # get column_layout and col sizes
  foreach(line ${lines})
    map_keys(${line})
    ans(keys)
    
    foreach(key ${keys})  
      map_tryget(${column_layout} ${key})
      ans(res)
      
      map_tryget(${line} ${key})
      ans(val)
      string(LENGTH "${val}" len)
        
      if(${len} GREATER "0${res}")
        map_set(${column_layout} ${key} "${len}")
      endif()
    endforeach()
  endforeach()


  map_keys(${column_layout})
  ans(headers)
  set(res)
  set(separator)
  set(layout)
  set(first true)
  foreach(header ${headers})
    if(first)
      set(first false)
    else()
      set(res "${res} ")
      set(separator "${separator} ")
    endif()

    map_tryget(${column_layout} "${header}")
    ans(size)
    string_pad("${header}" "${size}")
    ans(header)    
    set(res "${res}${header}")
    string_repeat("=" "${size}")
    ans(sep)
    set(separator "${separator}${sep}")
  endforeach()

  set(res "${res}\n${separator}\n")
  

  foreach(line ${lines})
    set(first true)    
    foreach(header ${headers})
      if(first)
        set(first false)
      else()
        set(res "${res} ")      
      endif()
      map_tryget(${column_layout} "${header}")
      ans(size)
      map_tryget(${line} "${header}")
      ans(val)
      string_pad("${val}" ${size})
      ans(val)
      set(res "${res}${val}")
    endforeach()
    set(res "${res}\n")
  endforeach()

  return_ref(res)
endfunction()




# creates a new xml node
# {
#   tag:'tag string'
#   //child_nodes:[xml_node, ...]
#   //parent:xml_node
#   attrs: {  }
#   value: 'string'
#   
# }
function(xml_node tag value attrs)
  obj("${attrs}")
  ans(attrs)
  map()
    kv(tag "${tag}")
    kv(value "${value}")
    kv(attrs "${attrs}")
  end()
  ans(res)
  return_ref(res)
endfunction()





  function(xml_parse_attrs xml tag attr)
    xml_parse_tags("${xml}" "${tag}")
    ans(nodes)
    set(res)
    foreach(node ${nodes})
      map_tryget(${node} attrs)
      ans(attrs)
      map_tryget("${attrs}" "${attr}")
      ans(it)
      list(APPEND res "${it}")
    endforeach()
    return_ref(res)
  endfunction()




## naive way of parsing xml tags
## returns a list of all matched xml nodes
## warning: does not supported nested nodes of same name!! and no tag whithout closing tag: <test/>
## {
##  value:"content",
##  attrs:{
##    key:"val",
##    key:"val",
##    ...
##  }
## }
function(xml_parse_tags xml tag)
  set(regex_str "\\\"([^\\\"]*)\\\"")
  set(regex_attrs "([a-zA-Z_-][a-zA-Z0-9_-]*) *= *${regex_str}")
  set(regex "< *${tag}([^>]*)>(.*)</ *${tag} *>")
  string(REGEX MATCHALL "${regex}"  output "${xml}")

  set(res)
  foreach(match ${output})
    string(REGEX REPLACE "${regex}" "\\1" attrs "${match}") 
    string(REGEX REPLACE "${regex}" "\\2" match "${match}") 


    map()
      kv(tag "${tag}")
      kv(value "${match}")    
      map(attrs)
        string(REGEX MATCHALL "${regex_attrs}" attrs "${attrs}")
        foreach(attr ${attrs})
          string(REGEX REPLACE "${regex_attrs}" "\\1" key "${attr}")
          string(REGEX REPLACE "${regex_attrs}" "\\2" val "${attr}")
          kv("${key}" "${val}")
        endforeach()
      end()
    end()
    ans(t)
    list(APPEND res ${t})

  endforeach()

  return_ref(res)

endfunction()





  function(xml_parse_values xml tag)
    xml_parse_tags("${xml}" "${tag}")
    ans(nodes)
    set(res)
    foreach(node ${nodes})
      nav(node.value)
      ans(val)
      list(APPEND res "${val}")
    endforeach()
    return_ref(res)
  endfunction()




  ## (${ARGC}) => 
  ## 
  macro(arguments_encoded_list __arg_count)
    set(__arg_res)   
    if(${__arg_count} GREATER 0)
      math(EXPR __last_arg_index "${__arg_count} - 1")
      foreach(i RANGE 0 ${__last_arg_index} )        
        string_encode_list("${ARGV${i}}")
        list(APPEND __arg_res "${__ans}")
      endforeach()
      set(__ans "${__arg_res}")
    else()
      set(__ans)
    endif()
  endmacro()


    ## (${ARGC}) => 
  ## 
  macro(arguments_encoded_list2 __arg_begin __arg_end)
    set(__arg_res)   
    if(${__arg_end} GREATER ${__arg_begin})
      math(EXPR __last_arg_index "${__arg_end} - 1")
      foreach(i RANGE ${__arg_begin} ${__last_arg_index} )        
        encoded_list("${ARGV${i}}")
        list(APPEND __arg_res "${__ans}")
      endforeach()
      set(__ans "${__arg_res}")
    else()
      set(__ans)
    endif()
  endmacro()




  macro(arguments_sequence __begin __end)
    arguments_encoded_list2("${__begin}" "${__end}")
    ans(__list)
    sequence_new()
    ans(__result)
    foreach(__sublist ${__list})
      encoded_list_decode("${__sublist}")
      ans(__sublist)
      sequence_add("${__result}" "${__sublist}")
    endforeach()
    set(__ans "${__result}")
  endmacro()






## returns the argument string which was passed to the parent function
## it takes into considerations quoted arguments
## todo: start and endindex
macro(arguments_string __arg_begin __arg_end)
  set(__arg_res)   
  if(${__arg_end} GREATER 0)
    math(EXPR __last_arg_index "${__arg_end} - 1")
    foreach(i RANGE 0 ${__last_arg_index})
      set(__current "${ARGV${i}}")
      if("${__current}_" MATCHES "(^_$)|(;)|(\\\")")
        set(__current "\"${__current}\"")
      endif()
      set(__arg_res "${__arg_res} ${__current}")
    endforeach()
    string(SUBSTRING "${__arg_res}" "1" "-1" __ans)  
  else()
    set(__ans)
  endif()
endmacro()





# is the same as function_capture.
# deprecate one of the two
#
# binds variables to the function
# by caputring their current value and storing
# them
# let funcA : ()->res
# bind(funcA var1 var2)
# will store var1 and var2 and provide them to the funcA call
function(bind func )
  cmake_parse_arguments("" "" "as" "" ${ARGN})
  if(NOT _as)
    function_new()
    ans(_as)
  endif()

  # if func is not a command import it
  if(NOT COMMAND "${func}")
    function_new()
    ans(original_func)
    function_import("${func}" as ${original_func} REDEFINE)
  else()
    set(original_func "${func}")
  endif()

  set(args ${_UNPARSED_ARGUMENTS})

  set(bound_args)
  foreach(arg ${args})
    set(bound_args "${bound_args}\nset(${arg} \"${${arg}}\")")
  endforeach()

  set(evaluate "function(${_as})
${bound_args}
${original_func}(\${ARGN})    
return_ans()
endfunction()")
  set_ans("")
  eval("${evaluate}")
  return_ref(_as)
endfunction()




# dynamic function call method
# can call the following
# * a cmake macro or function
# * a cmake file containing a single function
# * a lambda expression (see lambda())
# * a object with __call__ operation defined
# * a property reference ie this.method()
# CANNOT  call 
# * a navigation path
  # no output except through return values or referneces
  function(call __function_call_func __function_call_paren_open)

    return_reset()
    set(__function_call_args ${ARGN})

    list_pop_back(__function_call_args)
    ans(__function_call_paren_close)
    
    if(NOT "_${__function_call_paren_open}${__function_call_paren_close}" STREQUAL "_()")
      message("open ${__function_call_paren_open} close ${__function_call_paren_close}")
      message(WARNING "expected opening and closing parentheses for function '${__function_call_func}' '${ARGN}' '${__function_call_args}'")
    endif()

    if(COMMAND "${__function_call_func}")
      set_ans("")
      eval("${__function_call_func}(\${__function_call_args})")
      return_ans()
    endif()

    


    if(DEFINED "${__function_call_func}")
      call("${${__function_call_func}}"(${__function_call_args}))
      return_ans()
    endif()

    is_address("${__function_call_func}")
    ans(isref)
    if(isref)
      obj_call("${__function_call_func}" ${__function_call_args})
      return_ans()
    endif()

    propis_address("${__function_call_func}")
    ans(ispropref)
    if(ispropref)
      propref_get_key("${__function_call_func}")
      ans(key)
      propref_get_ref("${__function_call_func}")
      ans(ref)

      obj_member_call("${ref}" "${key}" ${__function_call_func})

    endif()

    lambda2_tryimport("${__function_call_func}" __function_call_import)
    ans(success)
    if(success)
      __function_call_import(${__function_call_args})
      return_ans()
    endif()


    if(DEFINED "${__function_call_func}")
      call("${__function_call_func}"(${__function_call_args}))
      return_ans()
    endif()


    is_function(is_func "${__function_call_func}")
    if(is_func)
      function_import("${__function_call_func}" as __function_call_import REDEFINE)
      __function_call_import(${__function_call_args})
      return_ans()
    endif()

    if("${__function_call_func}" MATCHES "^[a-z0-9A-Z_-]+\\.[a-z0-9A-Z_-]+$")
      string_split_at_first(__left __right "${__function_call_func}" ".")
      is_address("${__left}")
      ans(__left_isref)
      if(__left_isref)
        obj_member_call("${__left}" "${__right}" ${__function_call_args})  
        return_ans()
      endif()
      is_address("${${__left}}")
      ans(__left_isrefref)
      if(__left_isrefref)
        obj_member_call("${${__left}}" "${__right}" ${__function_call_args})
        return_ans()
      endif()
    endif()

    nav(__function_call_import = "${__function_call_func}")
    if(__function_call_import)
         call("${__function_call_import}"(${__function_call_args}))
      return_ans()
    endif()

   message(FATAL_ERROR "tried to call a non-function:'${__function_call_func}'")
  endfunction()




function(call2 callable)
  callable("${callable}")
  ans(callable)
  callable_call("${callable}")
  return_ans()
endfunction()

## faster version
function(call2 callable)
  callable_function("${callable}")
  eval("${__ans}(${ARGN})")
  set(__ans ${__ans} PARENT_SCOPE)
endfunction()




function(callable input)
  string(MD5  input_key "${input}" )
  get_propertY(callable GLOBAL PROPERTY "__global_callables.${input_key}")

  if(NOT callable)
    callable_new("${input}")
    ans(callable)

    checksum_string("${callable}")
    ans(callable_key)

    map_set_hidden(__global_callables "${input_key}" ${callable})
    map_set_hidden(__global_callables "${callable_key}" ${callable})

    map_get_special(${callable} callable_function)
    ans(function)

    map_set_hidden(__global_callable_functions "${input_key}" ${function})
    map_set_hidden(__global_callable_functions "${callable_key}" ${function})

  endif()
  set(__ans ${callable} PARENT_SCOPE)
endfunction()






function(callable_call callable)
  map_get_special("${callable}" callable_function)
  eval("${__ans}(${ARGN})")
  set(__ans "${__ans}" PARENT_SCOPE)
endfunction()







## returns the cmake function for the specified callable
function(callable_function input)
  string(MD5  input_key "${input}" )
  get_propertY(callable_func GLOBAL PROPERTY "__global_callable_functions.${input_key}")
  if(NOT callable_func)
    callable("${input}")
    ans(callable)
    get_propertY(callable_func GLOBAL PROPERTY "__global_callable_functions.${input_key}")
  endif()
  set(__ans ${callable_func} PARENT_SCOPE)
endfunction()




function(callable_new input)

  map_new()
  ans(callable)
  function_import("${input}")
  ans(callable_func)
  map_set_special("${callable}" callable_function "${callable_func}")
  map_set_special("${callable}" callable_input "${input}" )
  return_ref(callable)
endfunction()





  function(is_callable callable)
    map_get_special("${callable}" callable_function)
    ans(func)
    if(COMMAND "${func}")
      return(true)
    endif()
    return(false)
  endfunction()





function(check_function func)
	is_function(res "${func}")
	if(NOT res)
		message(FATAL_ERROR "expected a function instead got: '${func}'")
	endif()
endfunction()




## (["[" <capture vars> "]"] <callable> "(" (<argument>|<assignment>)* ")" ["=>" <?func_name>(<arg names>)  ])->
##
##
function(curry_compile_encoded_list out_func)
  #arguments_encoded_list(${ARGC})
  #ans(arguments)
  set(arguments ${ARGN})
  string_codes()
  set(regex_evaluates_to "=>")
  if("${arguments}" MATCHES "(.*);?${regex_evaluates_to};(.*)")
    set(definition "${CMAKE_MATCH_1}")
    set(invocation "${CMAKE_MATCH_2}")
  else()
    set(invocation "${arguments}")
    set(definition)
  endif()

  list_peek_front(invocation)
  ans(invocation_capture)

  if("${invocation_capture}" MATCHES "^${bracket_open_code}(.*)${bracket_close_code}$")
    string_decode_list("${CMAKE_MATCH_1}")
    ans(invocation_capture)
    list_pop_front(invocation)
  else()
    set(invocation_capture)
  endif()

  set(capture_code)
  foreach(capture ${invocation_capture})
    # todo capture by value
    set(capture_code "${capture_code}\n  set(${capture} \"${${capture}}\")")
  endforeach()

  regex_cmake()

  list_pop_front(invocation)
  ans(callable)

  string_decode_list("${callable}")
  ans(callable)

  function_import("${callable}")
  ans(invocation_name)

  set(invocation "${invocation_name};${invocation}")
  if("${invocation}" MATCHES "^(${regex_cmake_identifier});\\(;(.*);\\)")
    set(invocation_name "${CMAKE_MATCH_1}")
    set(invocation_args "${CMAKE_MATCH_2}")
  elseif("${invocation}" MATCHES "^(${regex_cmake_identifier})")
    set(invocation_name "${CMAKE_MATCH_1}")
    set(invocation_args "/*")
  endif()

  if("${definition}" MATCHES "^(${regex_cmake_identifier});\\(;?(.*);\\)")
    set(definition_name "${CMAKE_MATCH_1}")
    set(definition_args "${CMAKE_MATCH_2}")
  elseif("${definition}" MATCHES "^(${regex_cmake_identifier});?$")
    set(definition_name "${CMAKE_MATCH_1}")
    set(definition_args )
  elseif("${definition}" MATCHES "^\;?\\(;?(.*);\\)")
    set(definition_name)
    set(definition_args "${CMAKE_MATCH_1}")
  endif()

  if(NOT definition_name)
    function_new()
    ans(definition_name)
  endif()



  map_new()
  ans(assignments)


  set(arg_counter 0)
  set(arg_name_prefix __arg_)
  set(input_args)

  foreach(argument ${definition_args})
    string_decode_list("${argument}")
    ans(argument)
    set(argument_name "__${argument}")
    map_set(${assignments} ${argument} "${argument_name}")
    set(input_args "${input_args} ${argument_name}")
  endforeach()

  set(regex_arg_replacement "\\/(${regex_cmake_identifier}|\\*)")
  set(regex_pos_replacement "\\/(0|([1-9][0-9]*))")
  set(output_args)
  foreach(argument ${invocation_args})
    string_decode_list("${argument}")
    ans(argument)
    if("${argument}" MATCHES "^${regex_pos_replacement}$")
      set(argument_id "${CMAKE_MATCH_1}")
      set(argument_out "\${ARGV${argument_id}}")
    elseif("${argument}" MATCHES "^${regex_arg_replacement}$")
      set(argument_id "${CMAKE_MATCH_1}")
      if("${argument_id}" STREQUAL "*")
        set(argument_out "\${ARGN}")
      else()
        map_tryget("${assignments}" "${argument_id}")
        ans(argument_out)
        set(argument_out "\${${argument_out}}")
      endif()
    else()
      argument_escape("${argument}")
      ans(argument_out)
    endif()
    set(output_args "${output_args} ${argument_out}")
  endforeach()
  if(NOT "${output_args}_" STREQUAL "_")
    string(SUBSTRING "${output_args}" 1 -1 output_args)
  endif()
  if(NOT "${input_args}_" STREQUAL "_")
    string(SUBSTRING "${input_args}" 1 -1 input_args)
  endif()

  set(code "function(${definition_name} ${input_args})${capture_code}\n  ${invocation_name}(${output_args})\n  return_ans()\nendfunction()")
  set(${out_func} "${definition_name}" PARENT_SCOPE)
  return_ref(code)

endfunction()

##
function(curry_compile)
  arguments_encoded_list(${ARGC})
  ans(arguments)
  curry_compile_encoded_list(__outfunc "${arguments}")
  return_ans()
endfunction()

##
function(curry3)
  arguments_encoded_list(${ARGC})
  ans(arguments)
  curry_compile_encoded_list(__outfunc "${arguments}")
  ans(code)
  eval("${code}")
  return_ref(__outfunc)
endfunction()




## captures variables from the current scope in the function
function(function_capture callable)
  set(args ${ARGN})
  list_extract_labelled_value(args as)
  ans(func_name)
  if(func_name STREQUAL "")
    function_new()
    ans(func_name)
  endif()

  set(captured_var_string)
  foreach(arg ${args})
    set(captured_var_string "${captured_var_string}set(${arg} \"${${arg}}\")\n")
  endforeach()

  function_import("${callable}")
  ans(callable)

  eval("
    function(${func_name})
      ${captured_var_string}
      ${callable}(\${ARGN})
      return_ans()
    endfunction()
  ")
  return_ref(func_name)
endfunction()







function(function_help result func)
	function_lines_get( "${func}")
	ans(res)
	set(res)
	foreach(line ${res})
		string(STRIP "${line}" line)
		if(line)
			string(SUBSTRING "${line}" 0 1 first_char)
			if(NOT ${first_char} STREQUAL "#")
				if(res)
					set(res "${res}\n")
				endif()
				set(res "${res}${line}")
			else()
				break()
			endif()
		endif()
	endforeach()
	return_value("${res}")
endfunction()




function(function_import callable)
  set(args ${ARGN})
  list_extract_flag(args REDEFINE)
  ans(redefine)
  list_extract_flag(args ONCE)
  ans(once)
  list_extract_labelled_value(args as)
  ans(function_name)

  if(callable STREQUAL "")
    message(FATAL_ERROR "no callable specified")
  endif()

  if(COMMAND "${callable}")
    if("${function_name}_" STREQUAL "_" OR "${callable}_" STREQUAL "${function_name}_")
      return_ref(callable)
    endif()
  endif()





  if(NOT function_name)
    if(COMMAND "${callable}")
      set(function_name "${callable}")
      return_ref(function_name)
    else()
      function_new()
      ans(function_name)
      set(redefine true)
    endif()
  endif()


  if(COMMAND "${function_name}" AND NOT redefine)
    if(once)
      return()
    endif()
    message(FATAL_ERROR "cannot import '${callable}' as '${function_name}' because it already exists")
  endif()


  lambda2_tryimport("${callable}" "${function_name}")
  ans(res)
  if(res)
    return_ref(function_name)
  endif()


  function_string_get("${callable}")
  ans(function_string)
  
  function_string_rename("${function_string}" "${function_name}")
  ans(function_string)
  
  function_string_import("${function_string}")

  return_ref(function_name)
endfunction()





function(function_import_dispatcher function_name)
    string(REPLACE ";" "\n" content "${ARGN}")

    string(REGEX REPLACE "([^\n]+)" "elseif(command STREQUAL \"\\1\")\n \\1(\${ARGN})\nreturn_ans()\n" content "${content}")
    eval("
        function(${function_name} command)
          if(false)
          ${content}
            endif()
          return()
        endfunction()

      ")
      return()
endfunction()


function(function_import_global_dispatcher function_name)
    get_cmake_property(commands COMMANDS)       
    list(REMOVE_ITEM commands else if elseif endif while function endwhile endfunction macro endmacro foreach endforeach)
    function_import_dispatcher("${function_name}" ${commands})
    return()
endfunction()




# imports the specified map as a function table which is callable via <function_name>
# whis is a performance enhancement 
function(function_import_table map function_name)
  map_keys(${map} )
  ans(keys)
  set("ifs" "if(false)\n")
  foreach(key ${keys})
    map_get(${map}  ${key})
    ans(command_name)
    set(ifs "${ifs}elseif(\"${key}\" STREQUAL \"\${switch}\" )\n${command_name}(\"\${ARGN}\")\nreturn_ans()\n")
  endforeach()
  set(ifs "${ifs}endif()\n")
set("evl" "function(${function_name} switch)\n${ifs}\nreturn()\nendfunction()")
   # message(${evl})
  set_ans("")
   
    eval("${evl}")
endfunction()






# returns the function content in a list of lines.
# cmake does nto support a list containing a strings which in return contain semicolon
# the workaround is that all semicolons in the source are replaced by a separate line containsing the string ![[[SEMICOLON]]]
# so the number of lines a function has is the number of lines minus the number of lines containsing only ![[[SEMICOLON]]]
function(function_lines_get  func)
	function_string_get( "${func}")
	ans(function_string)
	
	string(REPLACE ";" "![[[SEMICOLON]]]"  function_string "${function_string}")
	string(REPLACE "\n" ";" lines "${function_string}")
	set(res)
	foreach(line ${lines})
		string(FIND "${line}" "![[[SEMICOLON]]]" hasSemicolon)
		if(${hasSemicolon} GREATER "-1")
			string(SUBSTRING "${line}" 0 ${hasSemicolon} part1)
			math(EXPR hasSemicolon "${hasSemicolon} + 16")
			string(SUBSTRING "${line}" ${hasSemicolon} "-1" part2)

			#string(REPLACE "" "${sc}" line "${line}")
			set(res ${res} "${part1}" "![[[SEMICOLON]]]" "${part2}")
		else()
			set(res ${res} ${line})
		endif()
	endforeach()

	return_ref(res)
endfunction()




# creates a and defines a function (with random name)
function(function_new )
	#generate a unique function id

	set(name_base "${__current_constructor}_${__current_member}")
	string_normalize("${name_base}")
	ans(name_base)

	set(id "${name_base}")
	if("${name_base}" STREQUAL "_")
		set(name_base "__func")
		set(id "__func_1111111111")
	endif()

	while(TRUE)
		if(NOT COMMAND "${id}")
			#declare function
			function("${id}")
				message(FATAL_ERROR "function is declared, not defined")
			endfunction()
			return_ref(id)
		endif()
		#message("making_id because ${id} alreading existers")
		make_guid()
		ans(id)
		set(id "${name_base}_${id}")
	endwhile()


endfunction()

## faster, but less debug info 
macro(function_new )
	identifier(function)
endmacro()





function(function_parse function_ish)
  is_function(function_type "${function_ish}")
  if(NOT function_type)
    return()
  endif()
  function_string_get( "${function_ish}")
  ans(function_string)
  
  if(NOT function_string)
    return()
  endif()

  function_signature_regex(regex)
  function_signature_get( "${function_string}")
  ans(signature)

  string(REGEX REPLACE ${regex} "\\1" func_type "${signature}" )
  string(REGEX REPLACE ${regex} "\\2" func_name "${signature}" )
  string(REGEX REPLACE ${regex} "\\3" func_args "${signature}" )

  string(STRIP "${func_name}" func_name)

  # get args
  string(FIND "${func_args}" ")" endOfArgsIndex)
  string(SUBSTRING "${func_args}" "0" "${endOfArgsIndex}" func_args)

  if(func_args)
    string(REGEX MATCHALL "[A-Za-z0-9_\\\\-]+" all_args ${func_args})
  endif()

  string(SUBSTRING "${func_args}" 0 ${endOfArgsIndex} func_args)
  string(TOLOWER "${func_type}" func_type)


  map_new()
  ans(res)
  map_set(${res} type "${func_type}")
  map_set(${res} name "${func_name}")
  map_set(${res} args "${all_args}")
  map_set(${res} code "${function_string}")

  return(${res})
endfunction()






#
function(function_signature_get func)
	function_lines_get( "${func}")
  ans(lines)
	#function_signature_regex(regex)
	foreach(line ${lines})
		string(REGEX MATCH "^[ ]*([mM][aA][cC][rR][oO]|[fF][uU][nN][cC][tT][iI][oO][nN])[ ]*\\([ \n\r]*([A-Za-z0-9_\\\\-]*)(.+)\\)" found "${line}")
		if(found)
      return_ref(line)
		endif()
	endforeach()
  return()
endfunction()




function(function_signature_regex result)
	set(${result} "^[ ]*([mM][aA][cC][rR][oO]|[fF][uU][nN][cC][tT][iI][oO][nN])[ ]*\\([ ]*([A-Za-z0-9_\\\\-]*)(.*)\\)" PARENT_SCOPE)
endfunction()





# returns the implementation of the function (a string containing the source code)
# this only works for functions files and function strings. CMake does not offer
# a possibility to get the implementation of a defined function or macro.
function(function_string_get func)
	is_function_string(is_string "${func}")
	if(is_string)
		return_ref(func)
		return()
	endif()

	
	is_function_ref(is_ref "${func}")
	if(is_ref)
		is_address(${func} )
		ans(is_ref_ref)

		if(is_ref_ref)
			address_get(${func} )
			ans(res)
			return_ref(res)
			return()
		else()
			set(${func} ${${func}})
		endif()
	endif()


	path("${func}")
	ans(fpath)
	is_function_file(is_file "${fpath}")


	if(is_file)
		load_function(file_content "${fpath}")
		function_string_get( "${file_content}")
		ans(file_content)
		return_ref(file_content)
		return()
	endif()


	is_function_cmake(is_cmake_func "${func}")

	if(is_cmake_func)
		## todo: just return nothing as func is already correctly defined...
		set(source "macro(${func})\n ${func}(\${ARGN})\nendmacro()")
		return_ref(source)		
		return()
	endif()
	
	if(NOT (is_string OR is_file OR is_cmake_func)  )
		message(FATAL_ERROR "the following is not a function: '${func}' ")
	endif()
	return()	

	lambda_parse("${func}")
	ans(parsed_lambda)

	if(parsed_lambda)
		return_ref(parsed_lambda)
		return()
	#endif()


endfunction()




function(function_string_import function_string)
  set_ans("")
  eval("${function_string}")
  return()
endfunction()





# injects code into  function (right after function is called) and returns result
function(function_string_rename input_function new_name) 
	function_string_get( "${input_function}")
	ans(function_string)
	function_signature_regex(regex)

	function_lines_get( "${input_function}")
	ans(lines)
	
	foreach(line ${lines})
		string(REGEX MATCH "${regex}" found "${line}")
		if(found)
			string(REGEX REPLACE "${regex}"  "\\1(${new_name} \\3)" new_line "${line}")
			string_replace_first("${line}" "${new_line}" "${input_function}")
			ans(input_function)
			break()
		endif()
	endforeach()
	return_ref(input_function)
endfunction()




  function(invocation_arguments_sequence)
    arguments_sequence(0 ${ARGC})
    return_ans()
  endfunction()






  function(invocation_argument_encoded_list)
    arguments_encoded_list(${ARGC})
    return_ans()
  endfunction()






  function(invocation_argument_string)
    arguments_string(0 ${ARGC})
    return_ans()
  endfunction()




#returns true if the the val is a function string or a function file
function(is_function result val)
	is_lambda("${val}")
	ans(is_lambda)
	if(is_lambda)
		return(lambda)
	endif()

	is_function_string(is_func "${val}")
	if(is_func)
		return_value(string)
	endif()
	is_function_cmake(is_func "${val}")
	if(is_func)
		return_value(cmake)
	endif()
	
	if(is_function_called)
		return_value(false)
	endif()
	is_function_file(is_func "${val}")
	if(is_func)		
		return_value(file)
	endif()
	set(is_function_called true)
	is_function_ref(is_func "${val}")
	if(is_func)
		return_value(${is_func})
	endif()


	return_value(false)
endfunction()




function(is_function_cmake result name)
	if(COMMAND "${name}")
		return_value(true)
	else()
		return_value(false)
	endif()
endfunction()




function(is_function_file result function_file)
	path("${function_file}")
	ans(function_file)
	
	if(NOT EXISTS "${function_file}")
		return_value(false)
	endif()

	if(IS_DIRECTORY "${function_file}")
		return_value(false)
	endif()

	file(READ "${function_file}" input)
	if(NOT input)
		return_value(false)
	endif()
	#is_function_string(res ${input})
	is_function(res "${input}")
	
	return_value(${res})
endfunction()




function(is_function_ref result func)
	is_address("${func}" )
  ans(is_ref)
	if(NOT is_ref)
		return(false)
	endif()
	address_get(${func} )
  ans(val)
	is_function(res "${val}")
	return_value(${res})
	
endfunction()




#returns true if the the string val is a function
function(is_function_string result val)
	if(NOT val)
		return_value(false)
	endif()
	#string(MD5 hash "${val}")
	#set(hash "hash_${hash}")
	#get_property(was_checked GLOBAL PROPERTY "${hash}")
	#if(was_checked)
	#return_value(${was_checked})
	#endif()

	string(REGEX MATCH ".*([mM][aA][cC][rR][oO]|[fF][uU][nN][cC][tT][iI][oO][nN])[ ]*\\(" function_found "${val}")
	if(NOT function_found)
		return_value(false)
	endif()
	#set_property(GLOBAL PROPERTY "${hash}" true)
	return_value(true)

endfunction()





function(is_lambda callable)
  if("${callable}" MATCHES "^\\[[a-zA-Z0-9_ ]*]*\\]\\([[a-zA-Z0-9_ ]*\\)")
    return(true)
  endif()
    return(false)
endfunction()




##
## returns the cmake function that this lambda was compiled to
function(lambda2 source)
  lambda2_instanciate("${source}")
  ans(lambda)
  map_tryget(${lambda} function_name)
  return_ans()
endfunction()






##
## compiles a lambda expression to valid cmake source and returns it
## {{a}} -> ${a}
## ["["<capture>"]"]["("<arg defs>")"] [(<expression>";")*]
## 
## 
function(lambda2_compile source)
  string_encode_list("${source}")
  ans(source)
  string_codes()
  regex_cmake()

  string_take_whitespace(source)

  set(capture_group_regex "${bracket_open_code}([^${bracket_close_code}]*)${bracket_close_code}")
  if("${source}" MATCHES "^(${capture_group_regex})(.*)")
    set(capture "${CMAKE_MATCH_2}")
    set(source "${CMAKE_MATCH_3}")
    string(REPLACE " " ";" capture "${capture}")
  else() 
    set(capture)
  endif()

  string_take_whitespace(source)
  if("${source}" MATCHES "^\\(([^\\)]*)\\)(.*)")
    set(signature "${CMAKE_MATCH_1}")
    set(source "${CMAKE_MATCH_2}")
  else()

  endif()



  string_take_whitespace(source)

  lambda2_compile_source("${source}")
  ans(cmake_source)
    




  map_capture_new(signature capture source cmake_source)

  return_ans()

endfunction()






  function(lambda2_compile_source source)
    string(ASCII 5 string_token)
    
    ## remove semicolons and brackets
    string_encode_list("${source}")
    ans(source)

    #  extract all delimited strings
    regex_delimited_string(' ')
    ans(regex_delimited_string)
    string(REGEX MATCHALL "${regex_delimited_string}" strings "${source}")
    string(REGEX REPLACE "${regex_delimited_string}" "${string_token}" source "${source}")


    ## re add semicolons and brackets
    string_decode_list("${source}")
    ans(source)

    ## replace ; with \n and commas with ;
    set(code)
    foreach(line ${source})
      string(REPLACE "," ";" line "${line}")
      set(code "${code}${line}\n")
    endforeach()
    

    ## resubistitute all extracted strings
    while(true)
      list_pop_front(strings)
      ans(current_string)
      if(NOT current_string)
        break()
      endif()
      string_decode_delimited("${current_string}" ' ')
      ans(current_string)

      string_decode_list("${current_string}")
      ans(current_string)

      cmake_string_escape("${current_string}")
      ans(current_string)

      string_replace_first("${string_token}" "\"${current_string}\"" "${code}")
      ans(code)
    endwhile()

    regex_cmake()

    ## replace {{}} with ${__ans}
    string(REPLACE  "{{}}" "${string_token}" code "${code}" )
    string(REGEX REPLACE "${string_token}" "${string_token}{__ans}" code "${code}")

    ## replace {{<identifier>}} with ${<identifier>}
    string(REGEX REPLACE "{{(${regex_cmake_identifier})}}" "${string_token}{\\1}" code "${code}")
    string(REPLACE "${string_token}" "\$" code "${code}" )

    ## end with returns_ans which forwards last return value
    set(code "${code}return_ans()")
    return_ref(code)

  endfunction()




function(lambda2_tryimport callable)
  if("${callable}" MATCHES "^\\[[a-zA-Z0-9_ ]*]*\\]\\([[a-zA-Z0-9_ ]*\\)")
    lambda2_instanciate("${callable}" ${ARGN})
    ans(res)
    return_ref(res)
  endif()
  return()
endfunction()







  function(lambda2_instanciate source)

    lambda2_compile("${source}")
    ans(lambda)

    map_tryget(${lambda} capture)
    ans(captures)
    set(capture_code)    
    foreach(capture ${captures})
      set(capture_code "${capture_code}\n  set(${capture} \"${${capture}}\")")
    endforeach()


    set(function_name ${ARGN})
    if(NOT function_name)
      function_new()
      ans(function_name)
    endif()
    map_set(${lambda} function_name ${function_name})

    map_tryget(${lambda} cmake_source)
    ans(cmake_source)
    map_tryget(${lambda} signature)
    ans(signature) 
    set(source "function(${function_name} ${signature})${capture_code}\n${cmake_source}\nendfunction()")
    eval("${source}")
    map_set(${lambda} cmake_function "${source}")
    return_ref(lambda)
  endfunction()





# reads a functions and returns it
function(load_function result file_name)	
	file(READ ${file_name} func)	
	set(${result} ${func} PARENT_SCOPE)
endfunction()




# allows a single line call with result 
# ie rcall(some_result = obj.getSomeInfo(arg1 arg2))
function(rcall __rcall_result_name equals __callable)
  set_ans("")
  call("${__callable}" ${ARGN})
  ans(res)
  set(${__rcall_result_name} ${res} PARENT_SCOPE)
  return_ref(res)
endfunction()






function(save_function file_name function_string)
	
	file(WRITE "${file_name}" "${function_string}")
endfunction()





function(try_call)
  set(args ${ARGN})
  list_pop_front(args)
  ans(func)
  is_function(is_func "${func}")
  if(is_func)
    return()
  endif()
  call(${ARGN})
  return_ans()
endfunction()




## defines the function called ${function_name} to call an operating system specific function
## uses ${CMAKE_SYSTEM_NAME} to look for a function called ${function_name}${CMAKE_SYSTEM_NAME}
## if it exists it is wrapped itno ${function_name}
## else ${function_name} is defined to throw an error if it is called
function(wrap_platform_specific_function function_name)
  os()
  ans(os_name)
  set(specificname "${function_name}_${os_name}")
  if(NOT COMMAND "${specificname}")      
    eval("
    function(${function_name})
      message(FATAL_ERROR \"operation is not supported on ${os_name} - look at document of '${function_name}' and implement a function with a matching interface called '${specificname}' for you own system\")        
    endfunction()      
    ")
  else()
    eval("
      function(${function_name})
        ${function_name}_${os_name}(\${ARGN})
        return_ans()
      endfunction()
    ")
    
  endif()
  return()
endfunction()






  function(command_line_handler)
    this_set(name "${ARGN}")

    ## forwards the object call operation to the run method
    this_declare_call(call)
    function(${call})

      obj_member_call(${this} run ${ARGN})
      ans(res)
      return_ref(res)
    endfunction()

    method(run)
    function(${run})
      handler_request(${ARGN})
      ans(request)
      assign(handler = this.find_handler(${request}))
      list(LENGTH handler handler_count)  


      if(${handler_count} GREATER 1)
        return_data("{error:'ambiguous_handler',description:'multiple command handlers were found for the request',request:$request}" )
      endif()

      if(NOT handler)
        return_data("{error:'no_handler',description:'command runner could not find an appropriate handler for the specified arguments',request:$request}")
      endif() 
      ## remove first item
      assign(request.input[0] = '') 
      set(parent_handler ${this})
      assign(result = this.execute_handler(${handler} ${request}))
      return_ref(result)

    endfunction()


    method(run_interactive)
    function(${run_interactive})
      if(NOT ARGN)
        echo_append("please enter a command>")
        read_line()
        ans(command)
      else()
        echo("executing command '${ARGN}':")
        set(command "${ARGN}")
      endif()
      obj_member_call(${this} run ${command})
      ans(res)
      table_serialize(${res})
      ans(formatted)
      echo(${formatted})
      return_ref(res)
    endfunction()

    ## compares the request to the handlers
    ## returns the handlers which matches the request
    ## can return multiple handlers
    method(find_handler)
    function(${find_handler})
      handler_request("${ARGN}")
      ans(request)
      this_get(handlers)
      handler_find(handlers "${request}")
      ans(handler)
      return_ref(handler)
    endfunction()

    ## executes the specified handler 
    ## the handler must not be part of this command runner
    ## it takes a handler and a request and returns a response object
    method(execute_handler)
    function(${execute_handler} handler)
      handler_request(${ARGN})
      ans(request)
      map_set(${request} runner ${command_line_handler})
      map_new()
      ans(response)
      handler_execute("${handler}" ${request} ${response})
      return_ref(response)
    endfunction()

    ## adds a request handler to this command handler
    ## request handler can be any function/function definition 
    ## or handler object
    method(add_handler)
    function(${add_handler})
      request_handler(${ARGN})
      ans(handler)
      if(NOT handler)
        return()
      endif()
      map_append(${this} handlers ${handler})
      
      return(${handler})
    endfunction()

  ## property contains a managed list of handlers
  property(handlers)
  ## setter
  function(${set_handlers} obj key new_handlers)
    map_tryget(${this} handlers)
    ans(old_handlers)
    if(old_handlers)
      list(REMOVE_ITEM new_handlers ${old_handlers})
    endif()

    set(result)
    foreach(handler ${new_handlers})
      set_ans("")
      obj_member_call(${this} add_handler ${handler})
      ans(res)
      list(APPEND result ${res})
    endforeach()
    return_ref(result)
  endfunction()
  ## getter
  function(${get_handlers})
    map_tryget(${this} handlers)
    return_ans()
  endfunction()


endfunction()









  ## creates a default handler from the specified cmake function
  function(handler_default func)
    if(NOT COMMAND "${func}")
      return()
    endif()
      function_new()
      ans(call_function)
      function_import("
        function(funcname request response)
          map_tryget(\${request} input)
          ans(input)
          ${func}(\"\${input}\")
          ans(res)
          map_set(\${response} output \"\${res}\")
          return(true)
        endfunction()
        " as ${call_function} REDEFINE)

    data("{
      callable:$call_function,
      display_name:$func,
      labels:$func
      }")
    ans(handler)

    request_handler("${handler}")
    return_ans()

  endfunction()







  ## executes a handler
  function(handler_execute handler request)
    request_handler(${handler})
    ans(handler)
    data(${request})
    ans(request)
    data(${ARGN})
    ans(response)
    if(NOT response)
      data("{output:''}")
      ans(reponse)
    endif()
    assign(!response.request = request)
    if(NOT handler)
      assign(!response.error = 'handler_invalid')
      assign(!response.message = "'handler was not valid'")
    else()
      assign(!response.handler = handler)
      map_tryget(${handler} callable)
      ans(callback)
      call("${callback}"("${request}" "${response}"))
      ans(result)
    endif()
    return_ref(response)
  endfunction()




# returns those handlers in handler_lst which match the specified request  
  function(handler_find handler_lst request)
    set(result)
    foreach(handler ${${handler_lst}})
      handler_match(${handler} ${request})
      ans(res)
      if(res)
        list(APPEND result ${handler})
      endif()
    endforeach()

    return_ref(result)
  endfunction() 





## checks of the handler can handle the specified request
## this is done by look at the first input argument and checking if
## it is contained in labels
function(handler_match handler request)
    map_tryget(${handler} labels)
    ans(labels)

    map_tryget(${request} input)
    ans(input)

    list_pop_front(input)
    ans(cmd)

    list_contains(labels "${cmd}")
    ans(is_match)

    return_ref(is_match)
endfunction()





  function(handler_request)
    set(request "${ARGN}")
    is_map("${request}")
    ans(is_map)

    if(NOT is_map)
      map_new()
      ans(request)
      map_set(${request} input ${ARGN})
    endif()
    return_ref(request)
  endfunction()




## creates a handler 
## 
function(request_handler handler)
  data("${handler}")
  ans(handler)
  is_map(${handler})
  ans(is_map)
  
  if(is_map)  
    map_tryget(${handler} callable)
    ans(callable)
    if(NOT COMMAND "${callable}")
      function_new()
      ans(new_callable)
      function_import("${callable}" as "${new_callable}" REDEFINE)
      map_set(${handler} callable "${new_callable}")
    endif()
    return(${handler})
  endif()

  if(COMMAND "${handler}")
    set(callable ${handler})
    if(NOT ARGN)
      handler_default("${callable}")
      return_ans()
    endif()
  else()
    function_new()
    ans(callable)
    function_import(${handler} as ${callable} REDEFINE)
    set(callable ${callable})
  endif()
  map_capture_new(
    callable
  )
  return_ans()
endfunction()






  function(indent str)
    indent_get(${ARGN})
    ans(indent)
    set(str "${indent}${str}")
    return_ref(str)
  endfunction()






  function(indent_get)
    list(LENGTH ARGN len)
    set(indent "  ")
    if(len)
      set(indent "${ARGN}")
    endif()
    indent_level()
    ans(lvl)
    string_repeat("${indent}" "${lvl}")
    return_ans()
  endfunction()





  function(indent_level)
    map_peek_back(global __indentlevelstack)
    ans(lvl)
    if(NOT lvl)
      return(0)
    endif()
    return_ref(lvl)
  endfunction()




## returns the current index level index which can be used to 
## restore the index level to a specific point
  function(indent_level_current)
    map_property_length(global __indentlevelstack)
    ans(idx)
    math(EXPR idx "${idx} -1")
    if("${idx}" LESS 0)
      set(idx 0)
    endif()
    return_ref(idx)
  endfunction()





  function(indent_level_pop)
    map_pop_back(global __indentlevelstack)
    indent_level_current()
    return_ans()
   endfunction()





  function(indent_level_push)
    set(new_lvl ${ARGN})
    if("${new_lvl}_" STREQUAL "_")
      set(new_lvl +1)
    endif()
    if("${new_lvl}" MATCHES "^[+\\-]")
      indent_level()
      ans(current_level)
      math(EXPR new_lvl "${current_level} ${new_lvl}")
    endif()
    map_push_back(global __indentlevelstack "${new_lvl}")
    indent_level_current()
    return_ans()
  endfunction()





  function(indent_level_restore)
    set(target ${ARGN})
    while(true)
      indent_level_current()
      ans(current_level)
      if("${target}" LESS "${current_level}")
        map_pop_back(global __indentlevelstack)
      else()
        break()
      endif()
    endwhile()
    return()
  endfunction()




function(test)



  indent_level_push(0)

  indent("asd" "...")
  ans(res)
  assert(${res} STREQUAL "asd")

  indent_level_push(+1)
  ans(storedlevel)
  indent("asd" "...")
  ans(res)
  assert(${res} STREQUAL "...asd")

  indent_level_push(+1)
  indent_level()
  ans(lvl)
  assert(${lvl} EQUAL 2)
  indent("asd" "...")
  ans(res)
  assert(${res} STREQUAL "......asd")


  indent_level_push()
  indent_level()
  ans(lvl)
  assert(${lvl} EQUAL 3)


  indent_level_restore(${storedlevel})
  indent_level()
  ans(lvl)
  assert(${lvl} EQUAL 1)

  
  

  indent_level_pop()


endfunction()





  function(query_select __lst input_callback)
    set(args ${ARGN})
    list_extract_flag(args --index)
    ans(index)
    set(i 0)
    list(LENGTH ${__lst} len)

    message_indent_push(+2)
    foreach(item ${${__lst}})
      message("${i}: ${item}") 
      math(EXPR i "${i} + 1")
    endforeach()
    message_indent_pop()
    while(true)
      echo_append("> ")
      call("${input_callback}"())
      ans(selected_index)
    
      string_isnumeric("${selected_index}")
      ans(isnumeric)
      if(isnumeric)
        if("${selected_index}" GREATER 0 AND ${selected_index} LESS ${len})
          break()
        else()
          message_indent("please enter a positive number < ${len}")
        endif()
      else()
        list(FIND ${__lst} "${selected_index}" selected_index)
        if(NOT "${selected_index}_" STREQUAL "_")
          break()
        endif()
        message_indent("please enter a number")
      endif()
    endwhile()
    if(index)
      return(${selected_index})
    endif()
    list(GET ${__lst} ${selected_index} selected_value)
    return_ref(selected_value)
  endfunction()





  function(listing)
    address_new()
    return_ans()    
  endfunction()








  function(listing_append listing line)
    string_combine(" " ${ARGN})
    ans(rest)
    string_encode_semicolon("${line}${rest}")
    ans(line)
    address_append("${listing}" "${line}")
    return()
  endfunction()






  function(listing_append_lines listing)
   foreach(line ${ARGN})
    listing_append(${listing} "${line}")
   endforeach()
  endfunction()






  function(listing_begin)
    listing()
    ans(lst)
    set(__listing_current "${lst}" PARENT_SCOPE)
  endfunction()






  function(listing_combine)
    listing()
    ans(lst)
    foreach(listing ${ARGN})
      address_get(${listing})
      ans(current)
      address_append("${lst}" "${current}")
    endforeach()
    return(${lst})
  endfunction()






  function(listing_compile listing)
    address_get("${listing}")
    ans(code)
    set(indent_on while if function foreach macro else elseif)
    set(unindent_on endwhile endif endfunction endforeach endmacro else elseif)
    set(current_indentation "")
    set(indented)


    foreach(line ${code})
      string(STRIP "${line}" line)
      string_take_regex(line "[^\\(]+")
      ans(func_name)
      if(func_name)
        list_contains(unindent_on ${func_name})
        ans(unindent)
        if(unindent)
          string_take(current_indentation "  ")
        endif()
        set(line "${current_indentation}${func_name}${line}")
        list_contains(indent_on ${func_name})
        ans(indent)
        if(indent)
          set(current_indentation "${current_indentation}  ")
        
        endif()
      endif()
      list(APPEND indented "${line}")
    endforeach()
    string(REPLACE ";" "\n" code "${indented}")
    string_decode_semicolon("${code}")
    ans(code)
    string(REPLACE "'" "\"" code "${code}")
    string(REGEX REPLACE "([^$]){([a-zA-Z0-9\\-_\\.]+)}" "\\1\${\\2}" code "${code}")
    return_ref(code)
  endfunction()





  function(listing_end)
    set(lst ${__listing_current})
    set(__listing_current PARENT_SCOPE)
    return_ref(lst)
  endfunction()






  macro(listing_end_compile)
    listing_end()
    listing_compile("${__ans}")
  endmacro()





  function(listing_include listing)
    listing_compile("${listing}")
    eval("${__ans}")
    return_ans()
  endfunction()







  function(line line)
    listing_append("${__listing_current}" "${line}")
  endfunction()









  function(listing_make_compile)
    listing()
    ans(uut)
    foreach(line ${ARGN})
      listing_append(${uut} "${line}")
    endforeach()
    listing_compile(${uut})
    return_ans()
  endfunction()





## `error(...)-><log entry>`
##
## Shorthand function for `log(<message> <refs...> --error)
## 
## see [log](#log)
##
function(error)
  log(--error ${ARGN})  
  return_ans()
endfunction()





## `log(<message:<string>> <refs...> [--error]|[--warning]|[--info]|[--debug]) -> <void>`
##
## This is the base function on which all of the logging depends. It transforms
## every log message into a object which can be consumed by listeners or filtered later
##
## *Note*: in its current state this function is not ready for use
##
## * returns
##   * the reference to the `<log entry>`
## * parameters
##   * `<message>` a `<string>` containing the message which is to be logged the data may be formatted (see `format()`)
##   * `<refs...>` you may pass variable references which will be captured so you can later check the state of the application when the message was logged
## * flags
##   * `--error`    flag indicates that errors occured
##   * `--warning`  flag indicates warnings
##   * `--info`     flag indicates a info output
##   * `--debug`    flag indicates a debug output
## * values
##   * `--error-code <code>` 
##   * `--level <n>` 
##   * `--push <section>` depth+1
##   * `--pop <section>`  depth-1
## * events
##   * `on_log_message`
##
## *Examples*
## ```
## log("this is a simple error" --error) => <% 
##   log("this is a simple error" --error) 
##   template_out_json("${__ans}")
## %>
## ```
function(log)
  event_handlers(on_log_message)
  ans(has_handlers)
  if(NOT has_handlers)
    return()
  endif()


  set(args ${ARGN})
  list_extract_flag(args --warning)
  list_extract_flag(args --info)
  list_extract_flag(args --debug)
  list_extract_flag(args --aftereffect)
  list_extract_flag(args --trace)
  ans(aftereffect)
  list_extract_flag(args --error)
  ans(is_error)
  list_extract_labelled_value(args --level)
  list_extract_labelled_value(args --push)
  list_extract_labelled_value(args --pop)
  list_extract_labelled_value(args --error-code)
  list_extract_labelled_value(args --function)
  ans(function)
  if(function)
    set(member_function ${function})
  endif()
  ans(error_code)
  map_new()
  ans(entry)
  set(message "${args}")
  map_format("${message}")
  ans(message)
  if(aftereffect)
    log_last_error_entry()
    ans(last_error)
    map_set(${entry} preceeding_error ${last_error})
  endif()
  map_set(${entry} message ${message})
  ##map_set(${entry} args this ${args})
  map_set(${entry} function ${member_function})
  map_set(${entry} error_code ${error_code})
  set(type)
  if(is_error OR NOT error_code STREQUAL "")
    set(type error)
  endif()
  event_emit(on_log_message ${entry})
  map_set(${entry} type ${type})
  address_append(log_record ${entry})
  return_ref(entry)
endfunction()





## `log_record_clear()-><void>`
## 
## removes all messages from the log record
##
##
function(log_record_clear)
  address_set(log_record)
  return()
endfunction()







## `log_last_error_entry()-><log entry>`
##
## returns the last log entry which is an error
## 
function(log_last_error_entry)
  address_get(log_record)
  ans(log_record)
  set(entry)
  while(true)
    if(NOT log_record)
      break()
    endif()
    list_pop_back(log_record)
    ans(entry)

    map_tryget(${entry} type)
    ans(type)
    if(type STREQUAL "error")
      break()
    endif()
  endwhile()
  return_ref(entry)
endfunction()






## `log_last_error_message()-><string>`
##
## returns the last logged error message
##
function(log_last_error_message)
  log_last_error_entry()
  ans(entry)
  if(NOT entry)
    return()
  endif()

  map_tryget(${entry} message)
  ans(message)


  return_ref(message)
endfunction()





## `log_last_error_print()-><void>`
##
## prints the last error message to the console  
##
function(log_last_error_print)
  log_last_error_entry()
  ans(entry)
  if(NOT entry)
    return()
  endif()

  message(FORMAT "Error in {entry.function}: {entry.message}")
  while(true)
    map_tryget(${entry} preceeding_error)
    ans(entry)
    if(NOT entry)
      break()
    endif()
    message(FORMAT "  because of {entry.function}: {entry.message}")
  endwhile()
  return()
endfunction()





## `log_print`
##
##
function(log_print)
  set(limit ${ARGN})

  address_get(log_record)
  ans(entries)

  list(LENGTH entries len)



  if("${limit}_" STREQUAL "_")
    math(EXPR limit "${len}")
  endif()

  if("${limit}" EQUAL 0)
    return()
  endif()

  foreach(i RANGE 1 ${limit})
    list_pop_back(entries)
    ans(entry)
    if(NOT entry)
      break()
    endif()
    message(FORMAT "{entry.type} @ {entry.function}: {entry.message}")
  endforeach()

endfunction()




# iterates a the graph with root nodes in ${ARGN}
# in breadth first order
# expand must consider cycles
function(bfs expand)
  queue_new()
  ans(queue)
  curry3(() => queue_push("${queue}" /0))
  ans(push)
  curry3(() => queue_pop("${queue}"))
  ans(pop)
  graphsearch(EXPAND "${expand}" PUSH "${push}" POP "${pop}" ${ARGN})
endfunction()






function(cmake_string_to_json str)
  string_decode_semicolon("${str}")
  ans(str)
  string(REPLACE "\\" "\\\\" str "${str}")
  string(REPLACE "\"" "\\\"" str "${str}")
  string(REPLACE "\n" "\\n" str "${str}")
  string(REPLACE "\t" "\\t" str "${str}")
  string(REPLACE "\t" "\\t" str "${str}")
  string(REPLACE "\r" "\\r" str "${str}")
  string(ASCII 8 bs)
  string(REPLACE "${bs}" "\\b" str "${str}")
  string(ASCII 12 ff)
  string(REPLACE "${ff}" "\\f" str "${str}")
  string(REPLACE ";" "\\\\;" str "${str}")
  set(str "\"${str}\"")
  return_ref(str)
endfunction()





# returns true if ref is a valid reference and its type is 'map'
function(is_map  ref )

	is_address("${ref}")
	ans(isref)
	if(NOT isref)
		return(false)
	endif()
	address_type_get("${ref}")
  ans(type)
	if(NOT "${type}" STREQUAL "map")
		return(false)
	endif()
	return(true)
endfunction()




# appends a value to the end of a map entry
function(map_append map key)
  get_property(isset GLOBAL PROPERTY "${map}.${key}" SET)
	if(NOT isset)
		map_set(${map} ${key} ${ARGN})
		return()
	endif()
  set_property(GLOBAL APPEND PROPERTY "${map}.${key}" ${ARGN})
endfunction()






function(map_append_string map key str)
  get_property(isset GLOBAL PROPERTY "${map}.${key}" SET)
  if(NOT isset)
    map_set(${map} ${key} "${str}")
    return()
  endif()
  get_property(property_val GLOBAL PROPERTY "${map}.${key}" )
  set_property(GLOBAL PROPERTY "${map}.${key}" "${property_val}${str}")
endfunction() 



function(map_append_string map key str)
  get_property(isset GLOBAL PROPERTY "${map}.${key}" SET)
  if(NOT isset)
    map_set(${map} ${key} "${str}")
  else()
    set_property(GLOBAL APPEND_STRING PROPERTY "${map}.${key}" "${str}")
  endif()
  set(__ans PARENT_SCOPE)
endfunction() 





## map_append_unique 
## 
## appends values to the <map>.<prop> and ensures 
## that <map>.<prop> stays unique 
function(map_append_unique map prop)
  map_tryget("${map}" "${prop}")
  ans(vals)
  list(APPEND vals ${ARGN})
  list_remove_duplicates(vals)
  map_set("${map}" "${prop}" ${vals})
endfunction()





function(map_delete this)
	map_exists(${this} )
	ans(res)
	if(NOT res)
		return()
	endif()
	map_check(${this})
	map_keys(${this} )
	ans(keys)

	foreach(key ${keys})
		map_remove(${this} ${key})
	endforeach()
	set_property(GLOBAL PROPERTY "${this}.__keys__")
endfunction()





  function(map_duplicate source)
    map_new()
    ans(duplicate)
    map_keys("${source}")
    ans(keys)
    foreach(key ${keys})
      map_tryget("${source}" "${key}")
      ans(val)
      map_set_hidden("${duplicate}" "${key}" ${val})
    endforeach()
    map_keys_set("${duplicate}" ${keys})
    return_ref(duplicate)
  endfunction()





function(map_get this key)
  set(property_ref "${this}.${key}")
  get_property(property_exists GLOBAL PROPERTY "${property_ref}" SET)
  if(NOT property_exists)
    message(FATAL_ERROR "map '${this}' does not have key '${key}'")    
  endif()
  
  get_property(property_val GLOBAL PROPERTY "${property_ref}")
  return_ref(property_val)  
endfunction()
# faster way of accessing map.  however fails if key contains escape sequences, escaped vars or @..@ substitutions
# if thats the case comment out this macro
macro(map_get __map_get_map __map_get_key)
  set(__map_get_property_ref "${__map_get_map}.${__map_get_key}")
  get_property(__ans GLOBAL PROPERTY "${__map_get_property_ref}")
  if(NOT __ans)
    get_property(__map_get_property_exists GLOBAL PROPERTY "${__map_get_property_ref}" SET)
    if(NOT __map_get_property_exists)
      json_print("${__map_get_map}")

      message(FATAL_ERROR "map '${__map_get_map}' does not have key '${__map_get_key}'")    
    endif()
  endif()  
endmacro()







  function(map_get_special map key)
    map_tryget("${map}" "__${key}__")
    return_ans()
  endfunction()

  ## faster
  macro(map_get_special map key)
    get_property(__ans GLOBAL PROPERTY "${map}.__${key}__")
  endmacro()







function(map_has this key )  
  get_property(res GLOBAL PROPERTY "${this}.${key}" SET)
  return(${res})
endfunction()

# faster way of accessing map.  however fails if key contains escape sequences, escaped vars or @..@ substitutions
# if thats the case comment out this macro
macro(map_has this key )  
  get_property(__ans GLOBAL PROPERTY "${this}.${key}" SET)
endmacro()








# returns all keys for the specified map
macro(map_keys this)
  get_property(__ans GLOBAL PROPERTY "${this}.__keys__")
  #return_ref(keys)
endmacro()
# returns all keys for the specified map
#function(map_keys this)
#  get_property(keys GLOBAL PROPERTY "${this}")
#  return_ref(keys)
#endfunction()





 function(map_new)
  address_new(map)
  return_ans()
endfunction()

## optimized version
 macro(map_new)
  address_new(map)
endmacro()





function(map_remove map key)
  map_has("${map}" "${key}")
  ans(has_key)
  ## set value to "" without updating key
  map_set_hidden("${map}" "${key}")
  if(NOT has_key)
    return(false)
  endif()
  get_property(keys GLOBAL PROPERTY "${map}.__keys__")
  list(LENGTH keys len)
  if(NOT len)
    returN(false)
  endif()
  list(REMOVE_ITEM keys "${key}")
  set_property(GLOBAL PROPERTY "${map}.__keys__" "${keys}")
  return(true)
endfunction()





## map_remove_item
##
## removes the specified items from <map>.<prop>
## returns the number of items removed
function(map_remove_item map prop)
  map_tryget("${map}" "${prop}")
  ans(vals)
  list_remove(vals ${ARGN})
  ans(res)
  if(res)
    map_set_hidden("${map}" "${prop}" "${vals}")
  endif()
  return_ref(res)
endfunction()




# set a value in the map
function(map_set this key )
  set(property_ref "${this}.${key}")
  get_property(has_key GLOBAL PROPERTY "${property_ref}" SET)
	if(NOT has_key)
		set_property(GLOBAL APPEND PROPERTY "${this}.__keys__" "${key}")
	endif()
	# set the properties value
	set_property(GLOBAL PROPERTY "${property_ref}" "${ARGN}")
endfunction()





function(map_set_hidden map property)
  set_property(GLOBAL PROPERTY "${map}.${property}" ${ARGN})
endfunction()





  function(map_set_special map key)
    map_set_hidden("${map}" "__${key}__" "${ARGN}")
  endfunction()




# tries to get the value map[key] and returns NOTFOUND if
# it is not found

function(map_tryget map key)
  get_property(res GLOBAL PROPERTY "${map}.${key}")
  return_ref(res)
endfunction()

# faster way of accessing map.  however fails if key contains escape sequences, escaped vars or @..@ substitutions
# if thats the case comment out this macro
macro(map_tryget map key)
  get_property(__ans GLOBAL PROPERTY "${map}.${key}")
endmacro()




# iterates a the graph with root nodes in ${ARGN}
# in depth first order
# expand must consider cycles
function(dfs expand)
  stack_new()
  ans(stack)
  curry3(() => stack_push("${stack}" /0))
  ans(push)
  curry3(() => stack_pop("${stack}" ))
  ans(pop)
  graphsearch(EXPAND "${expand}" PUSH "${push}" POP "${pop}" ${ARGN})
endfunction()






# emits events parsing a list of map type elements 
# expects a callback function that takes the event type string as a first argument
# follwowing events are called (available context variables are listed as subelements: 
# value
#   - list_length (may be 0 or 1 which is good for a null check)
#   - content_length (contains the length of the content)
#   - node (contains the value)
# list_begin
#   - list_length (number of elements the list contains)
#   - content_length (accumulated length of list elements + semicolon separators)
#   - node (contains all values of the lsit)
# list_end
#   - list_length(number of elements in list)
#   - node (whole list)
#   - list_char_length (length of list content)
#   - content_length (accumulated length of list elements + semicolon separators)
# list_element_begin
#   - list_length(number of elements in list)
#   - node (whole list)
#   - list_char_length (length of list content)
#   - content_length (accumulated length of list elements + semicolon separators)
#   - list_element (contains current list element)
#   - list_element_index (contains current index )   
# list_element_end
#   - list_length(number of elements in list)
#   - node (whole list)
#   - list_char_length (length of list content)
#   - content_length (accumulated length of list elements + semicolon separators)
#   - list_element (contains current list element)
#   - list_element_index (contains current index )
# visited_reference
#   - node (contains ref to revisited map)
# unvisited_reference
#   - node (contains ref to unvisited map)
# map_begin
#   - node( contains ref to map)
#   - map_keys (contains all keys of map)
#   - map_length (contains number of keys of map)
# map_end
#   - node( contains ref to map)
#   - map_keys (contains all keys of map)
#   - map_length (contains number of keys of map)
# map_element_begin
#   - node( contains ref to map)
#   - map_keys (contains all keys of map)
#   - map_length (contains number of keys of map)
#   - map_element_key (current key)
#   - map_element_value (current value)
#   - map_element_index (current index)
# map_element_end
#   - node( contains ref to map)
#   - map_keys (contains all keys of map)
#   - map_length (contains number of keys of map)
#   - map_element_key (current key)
#   - map_element_value (current value)
#   - map_element_index (current index)
function(dfs_callback callback)
  # inner function
  function(dfs_callback_inner node)
 

    is_map("${node}")
    ans(ismap)
    if(NOT ismap)
      list(LENGTH node list_length)
      string(LENGTH "${node}" content_length)
      if(${list_length} LESS 2)
        dfs_callback_emit(value)
      else()
        dfs_callback_emit(list_begin) 
        set(list_element_index 0)
        foreach(list_element ${node})
          list_push_back(path "${list_element_index}")
          dfs_callback_emit(list_element_begin)
          dfs_callback_inner("${list_element}")
          dfs_callback_emit(list_element_end)
          list_pop_back(path)
          math(EXPR list_element_index "${list_element_index} + 1")
        endforeach()
        dfs_callback_emit(list_end)
      endif()
      return()
    endif()

    map_tryget(${visited} "${node}")
    ans(was_visited)

    if(was_visited)
      dfs_callback_emit("visited_reference")
      return()
    else()
      dfs_callback_emit("unvisited_reference")
    endif()


    map_set(${visited} "${node}" true)

    map_keys(${node})
    ans(map_keys)

    list(LENGTH map_keys map_length)

    dfs_callback_emit(map_begin)

    
    set(map_element_index 0)
    foreach(map_element_key ${map_keys})
      map_tryget(${node} ${map_element_key})
      ans(map_element_value)
      list_push_back(path "${map_element_key}")
      dfs_callback_emit(map_element_begin)

      dfs_callback_inner("${map_element_value}")

      dfs_callback_emit(map_element_end)
      list_pop_back(path)

      math(EXPR map_element_index "${map_element_index} + 1")
    endforeach()


    dfs_callback_emit(map_end "${node}" )
  endfunction()

  function(dfs_callback callback)
#    curry3(dfs_callback_emit => "${callback}"(/0) as dfs_callback_emit)
    # faster
    eval("
function(dfs_callback_emit)
  ${callback}(\${ARGN})
endfunction()
")
    map_new()
    ans(visited)

   # foreach(arg ${ARGN})
   set(path)
    dfs_callback_inner("${ARGN}")
   # endforeach()
    return()
  endfunction()
  dfs_callback("${callback}" ${ARGN})
  return_ans()
endfunction()






# matches the object list 
function(list_match __list_match_lst )
  map_matches("${ARGN}")
  ans(predicate)
  list_where("${__list_match_lst}" "${predicate}")
  return_ans()
endfunction()







# returns all possible paths for the map
# (currently crashing on cycles cycles)
# todo: implement
function(map_all_paths)
  message(FATAL_ERROR "map_all_paths is not implemented yet")

  function(_map_all_paths event)
    if("${event}" STREQUAL "map_element_begin")
      address_get(${current_path})
      ans(current_path)
      set(cu)
    endif()
    if("${event}" STREQUAL "value")
      address_new(${})
    endif()
  endfunction()

  address_new()
  ans(current_path)
  address_new()
  ans(path_list)

  dfs_callback(_map_all_paths ${ARGN})
endfunction()





  ## returns the value at idx
  function(map_at map idx)
    map_key_at(${map} "${idx}")
    ans(key)
    map_tryget(${map} "${key}")
    return_ans()
  endfunction()




## captures the listed variables in the map
function(map_capture map )
  set(__map_capture_args ${ARGN})
  list_extract_flag(__map_capture_args --reassign)
  ans(__reassign)
  list_extract_flag(__map_capture_args --notnull)
  ans(__not_null)
  foreach(__map_capture_arg ${__map_capture_args})
    
    if(__reassign AND "${__map_capture_arg}" MATCHES "(.+)[:=](.+)")
      set(__map_capture_arg_key ${CMAKE_MATCH_1})
      set(__map_capture_arg ${CMAKE_MATCH_2})
    else()
      set(__map_capture_arg_key "${__map_capture_arg}")
    endif()
   # print_vars(__map_capture_arg __map_capture_arg_key)
    if(NOT __not_null OR NOT "${${__map_capture_arg}}_" STREQUAL "_")
      map_set(${map} "${__map_capture_arg_key}" "${${__map_capture_arg}}")
    endif()
  endforeach()
endfunction()






## captures a new map from the given variables
## example
## set(a 1)
## set(b 2)
## set(c 3)
## map_capture_new(a b c)
## ans(res)
## json_print(${res})
## --> 
## {
##   "a":1,
##   "b":2,
##   "c":3 
## }
function(map_capture_new)
  map_new()
  ans(__map_capture_new_map)
  map_capture(${__map_capture_new_map} ${ARGN})
  return(${__map_capture_new_map})
endfunction()






# removes all properties from map
function(map_clear map)
  map_keys("${map}")
  ans(keys)
  foreach(key ${keys})
    map_remove("${map}" "${key}")
  endforeach()
  return()
endfunction()




# copies the values of the source map into the target map by assignment
# (shallow copy)
function(map_copy_shallow target source)
  map_keys("${source}")
  ans(keys)

  foreach(key ${keys})
    map_tryget("${source}" "${key}")
    ans(val)
    map_set("${target}" "${key}" "${val}")
  endforeach()
  return()
endfunction()







# sets all undefined properties of map to the default value
function(map_defaults map defaults)
  obj("${defaults}")
  ans(defaults)
  if(NOT defaults)
    message(FATAL_ERROR "No defaults specified")
  endif()

  if(NOT map)
    map_new()
    ans(map)
  endif()

  map_keys("${map}")
  ans(keys)

  map_keys("${defaults}")
  ans(default_keys)


  if(default_keys AND keys)
    list(REMOVE_ITEM default_keys ${keys})
  endif()
  foreach(key ${default_keys})
    map_tryget("${defaults}" "${key}")
    ans(val)
    map_set("${map}" "${key}" "${val}")
  endforeach()
  return_ref(map)
endfunction()




function(map_edit)
	# function for editing a map by console commands
	set(options
		--sort
		--insert
		--reverse
		--remove-duplicates
		--set
		--append
		--remove
		--reorder
		--print
	)

	cmake_parse_arguments("" "${options}" "" "" ${ARGN})
	
	list(GET _UNPARSED_ARGUMENTS 0 navigation_expression)
	list(REMOVE_AT _UNPARSED_ARGUMENTS 0)
	set(arg ${_UNPARSED_ARGUMENTS})


	map_transform( "${arg}")
	ans(arg)
	map_navigate(value "${navigation_expression}")
	list_isvalid("${value}" )
	ans(islist)
	set(result_list)
	if(islist)
		set(result_list "${value}")
		address_get(${value} )
		ans(value)
	endif()


	if(_--remove)
		if(NOT arg)
			set(value )
		else()
			list(REMOVE_ITEM value "${arg}")
		endif()
	elseif(_--sort)
	elseif(_--reorder)

	elseif(_--insert)
		list(INSERT value "${arg}")
	elseif(_--reverse)
	elseif(_--remove-duplicates)
	elseif(_--set )
		set(value "${arg}")
	elseif(_--append)
		set(value "${value}" "${arg}")
	else()
		if(_--print)			
			address_print(${value})
		endif()
		return()
	endif()



	# modifiers
	if(_--remove-duplicates)
		list(REMOVE_DUPLICATES value)
	endif()

	if(_--sort)
		list(SORT value)
	endif()

	if(_--reverse)
		list(REVERSE value)
	endif()
	

	list(LENGTH value len)
	if(${len} GREATER 1)
		if(NOT result_list)
			list_new()
			ans(result_list)
		endif()
		address_set(${result_list} "${value}")	
		set(value ${result_list})
	endif()
	map_navigate_set("${navigation_expression}" "${value}")
	if(_--print)
		address_print("${value}")
	endif()
endfunction()




# ensures that the specified vars are a map
# parsing structured data if necessary
  macro(map_ensure)
    foreach(__map_ensure_arg ${ARGN})
      obj("${${__map_ensure_arg}}")
      ans("${__map_ensure_arg}")
    endforeach()
  endmacro()




function(map_extract navigation_expressions)
  cmake_parse_arguments("" "REQUIRE" "" "" ${ARGN})
  set(args ${_UNPARSED_ARGUMENTS})
  foreach(navigation_expression ${navigation_expressions})
    map_navigate(res "${navigation_expression}")
    list_pop_front( args)
    ans(current)
    if(_REQUIRE AND NOT res)
      message(FATAL_ERROR "map_extract failed: requires ${navigation_expression}")
    endif()

    if(current)
      set(${current} ${res} PARENT_SCOPE)
    else()
      if(NOT _REQUIRE)
       break()
      endif()
    endif()
  endforeach()
  foreach(arg ${args})
    set(${arg} PARENT_SCOPE)  
  endforeach()
  
endfunction()






  ## files non existing or null values of lhs with values of rhs
  function(map_fill lhs rhs)
    map_ensure(lhs rhs)
    map_iterator(${rhs})
    ans(it)
    while(true)
      map_iterator_break(it)
    
      map_tryget(${lhs} "${it.key}")
      ans(lvalue)

      if("${lvalue}_" STREQUAL "_")
        map_set(${lhs} "${it.key}" "${it.value}")
      endif()
    endwhile()
    return_ref(lhs)
  endfunction()





  function(map_flatten)
    set(result)
    foreach(map ${ARGN})
      map_values(${map})
      ans_append(result)
    endforeach()
    return_ref(result)
  endfunction()




# adds the keyvalues list to the map (if not map specified created one)
function(map_from_keyvaluelist map)
  if(NOT map)
    map_new()
    ans(map)
  endif()
  set(args ${ARGN})
  while(true)
    list_pop_front(args)
    ans(key)
    list_pop_front(args)
    ans(val)
    if(NOT key)
      break()
    endif()
    map_set("${map}" "${key}" "${val}")
  endwhile()
  return_ref(map)
endfunction()




## `(<map> <key> <any...>)-><any...>`
##
## returns the value stored in map.key or 
## sets the value at map.key to ARGN and returns 
## the value
function(map_get_default map key)
  map_has("${map}" "${key}")
  ans(has_key)
  if(NOT has_key)
    map_set("${map}" "${key}" "${ARGN}")
  endif()
  map_tryget("${map}" "${key}")
  return_ans()
endfunction()




## `(<map> <key>)-><map>`
##
## returns a map for the specified key
## creating it if it does not exist
##
function(map_get_map map key)
  map_tryget(${map} ${key})
  ans(res)
  is_address("${res}")
  ans(ismap)
  if(NOT ismap)
    map_new()
    ans(res)
    map_set(${map} ${key} ${res})
  endif()
  return_ref(res)
endfunction()







# returns true if map has all keys specified
#as varargs
function(map_has_all map)

  foreach(key ${ARGN})
    map_has("${map}" "${key}")
    ans(has_key)
    if(NOT has_key)
      return(false)
    endif()
  endforeach()
  return(true)

endfunction()






# returns true if map has any of the keys
# specified as varargs
function(map_has_any map)
  foreach(key ${ARGN})
    map_has("${map}" "${key}")
    ans(has_key)
    if(has_key)
      return(true)
    endif()
  endforeach()
  return(false)

endfunction()






# returns a copy of map with key values inverted
# only works correctly for bijective maps
function(map_invert map)
  map_keys("${map}")
  ans(keys)
  map_new()
  ans(inverted_map)
  foreach(key ${keys})
    map_tryget("${map}" "${key}")
    ans(val)
    map_set("${inverted_map}" "${val}" "${key}")
  endforeach()
  return_ref(inverted_map)
endfunction()





  function(map_isempty map)
    map_keys(${map})
    ans(keys)
    list(LENGTH keys len)
    if(len)
      return(false)
    else()
      return(true)
    endif()
  endfunction()






function(map_keys_append map)
  set_property(GLOBAL APPEND PROPERTY "${map}" ${ARGN})
endfunction()





function(map_keys_clear map)
  set_property(GLOBAL PROPERTY "${map}.__keys__")
endfunction()





function(map_keys_remove map)
  get_property(keys GLOBAL PROPERTY "${map}.__keys__" )
  if(keys AND ARGN)
    list(REMOVE_ITEM keys ${ARGN})
    set_property(GLOBAL PROPERTY "${map}.__keys__" ${keys})
  endif()
endfunction()





function(map_keys_set map)
  set_property(GLOBAL PROPERTY "${map}.__keys__" ${ARGN})
endfunction()





function(map_keys_sort map)
  get_property(keys GLOBAL PROPERTY "${map}.__keys__")
  if(keys)
    list(SORT keys)
    set_property(GLOBAL PROPERTY "${map}.__keys__" ${keys})
  endif()
endfunction()





  ## returns the key at the specified position
  function(map_key_at map idx)
    map_keys(${map})
    ans(keys)
    list_normalize_index(keys ${idx})
    ans(idx)
    list_get(keys ${idx})
    ans(key)
    return_ref(key)
  endfunction()







  ## checks if all fields specified in actual rhs are equal to the values in expected lhs
  ## recursively checks submaps
  function(map_match lhs rhs)
    if("${lhs}_" STREQUAL "${rhs}_")
      return(true)
    endif()


    list(LENGTH lhs lhs_length)
    list(LENGTH rhs rhs_length)

    if(NOT "${lhs_length}" EQUAL "${rhs_length}")
      return(false)
    endif()
  
    if(${lhs_length} GREATER 1)
      while(true)
        list(LENGTH lhs len)
        if(NOT len)
          break()
        endif()

        list_pop_back(lhs)
        ans(lhs_value)
        list_pop_back(rhs)
        ans(rhs_value)
        map_match("${lhs_value}" "${rhs_value}")
        ans(is_match)
        if(NOT is_match)
          return(false)
        endif()
      endwhile()
      return(true)
    endif() 

    is_map("${rhs}")
    ans(rhs_ismap)

    is_map("${lhs}")
    ans(lhs_ismap)

  
    if(NOT lhs_ismap OR NOT rhs_ismap)
      return(false)
    endif()


    map_iterator(${rhs})
    ans(it)

    while(true)
      map_iterator_break(it)

      map_tryget("${lhs}" "${it.key}")
      ans(lhs_value)

      map_match("${lhs_value}" "${it.value}")
      ans(values_match)

      if(NOT values_match)
        return(false)
      endif()

    endwhile()

    return(true)

  endfunction()





# returns a function which returns true of all 
function(map_matches attrs)
  obj("${attrs}")
  ans(attrs)
#  curry(map_match_properties(/1 ${attrs}))
  curry3(map_match_properties(/0 ${attrs}))
  return_ans()
endfunction()







# returns true if map's properties match all properties of attrs
function(map_match_properties map attrs)
  map_keys("${attrs}")
  ans(attr_keys)
  foreach(key ${attr_keys})

    map_tryget("${map}" "${key}")
    ans(val)
    map_tryget("${attrs}" "${key}")
    ans(pred)
   # message("matching ${map}'s ${key} '${val}' with ${pred}")
    if(NOT "${val}" MATCHES "${pred}")
      return(false)
    endif()
  endforeach()
  return(true)
endfunction()






# returns a copy of map without the specified keys (argn)
function(map_omit map)
  map_keys("${map}")
  ans(keys)
  if(ARGN)
    list(REMOVE_ITEM keys ${ARGN})
  endif()
  map_pick("${map}" ${keys})
  return_ans()
endfunction()




# returns a map with all properties except those matched by any of the specified regexes
function(map_omit_regex map)
  set(regexes ${ARGN})
  map_keys("${map}")
  ans(keys)

  foreach(regex ${regexes})
    foreach(key ${keys})
        if("${key}" MATCHES "${regex}")
          list_remove(keys "${key}")
        endif()
    endforeach()
  endforeach()


  map_pick("${map}" ${keys})

  return_ans()


endfunction()





  ## overwrites all values of lhs with rhs
  function(map_overwrite lhs rhs)
    obj("${lhs}")
    ans(lhs)
    obj("${rhs}")
    ans(rhs)

    map_iterator("${rhs}")
    ans(it)
    while(true)
      map_iterator_break(it)
      map_set("${lhs}" "${it.key}" "${it.value}")
    endwhile()
    return(${lhs})
  endfunction()







# returns a list key;value;key;value;...
# only works if key and value are not lists (ie do not contain ;)
function(map_pairs map)
  map_keys("${map}")
  ans(keys)
  set(pairs)
  foreach(key ${keys})
    map_tryget("${map}" "${key}")
    ans(val)
    list(APPEND pairs "${key}")
    list(APPEND pairs "${val}")
  endforeach()
  return_ref(pairs)
endfunction()





function(test)
  new()
  ans(obj)
  obj_set(${obj} "test1" "val1")
  obj_set(${obj} "test2" "val2")
  obj_set(${obj} "test3" "val3")


  obj_pick("${obj}" test1 test3)
  ans(res)
  assert(DEREF {res.test1} STREQUAL "val1")
  assert(DEREF {res.test3} STREQUAL "val3")

  obj_pick("${obj}" test4)
  ans(res)
  assert(res)
  assert(DEREF "_{res.test4}" STREQUAL "_")


endfunction()




# returns the value at the specified path (path is specified as path fragment list)
# e.g. map = {a:{b:{c:{d:{e:3}}}}}
# map_path_get(${map} a b c d e)
# returns 3
# this function is somewhat faster than map_navigate()
function(map_path_get map)
  set(args ${ARGN})
  set(current "${map}")
  foreach(arg ${args}) 
    if(NOT current)
      return()
   endif()
   map_tryget("${current}" "${arg}")
   ans(current)
  endforeach()
  return_ref(current)
endfunction()





# todo implement

function(map_path_set map path value)
  message(FATAL_ERROR "not implemented")
  if(NOT map)
    map_new()
    ans(map)
  endif()

  set(current "${map}")

  foreach(arg ${path})
    map_tryget("${current}" "${arg}")
    ans(current) 

  endforeach()

endfunction()






function(map_peek_back map prop)
  map_tryget("${map}" "${prop}")
  ans(lst)
  list_peek_back(lst)
  return_ans()
endfunction()





function(map_peek_front map prop)
  map_tryget("${map}" "${prop}")
  ans(lst)
  list_peek_front(lst)
  return_ans()
endfunction()





# returns a copy of map returning only the whitelisted keys
function(map_pick map)
    map_new()
    ans(res)
    foreach(key ${ARGN})
      obj_get(${map} "${key}")
      ans(val)

      map_set("${res}" "${key}" "${val}")
    endforeach()
    return("${res}")
endfunction()






# returns a map containing all properties whose keys were matched by any of the specified regexes
function(map_pick_regex map)
  set(regexes ${ARGN})
  map_keys("${map}")
  ans(keys)
  set(pick_keys)
  foreach(regex ${regexex})
    foreach(key ${keys})
      if("${key}" MATCHES "${regex}")
        list(APPEND pick_keys "${key}")
      endforeach()
    endforeach()
  endforeach()
  list(REMOVE_DUPLICATES pick_keys)
  map_pick("${map}" ${pick_keys})
  return_ans()
endfunction()







function(map_pop_back map prop)
  map_tryget("${map}" "${prop}")
  ans(lst)
  list_pop_back(lst)
  ans(res)
  map_set("${map}" "${prop}" ${lst})
  return_ref(res) 
endfunction()






function(map_pop_front map prop)
  map_tryget("${map}" "${prop}")
  ans(lst)
  list_pop_front(lst)
  ans(res)
  map_set("${map}" "${prop}" ${lst})
  return_ref(res)
endfunction()





macro(map_promote __map_promote_map)
  # garbled names help free from variable collisions
  map_keys(${__map_promote_map} )
  ans(__map_promote_keys)
  foreach(__map_promote_key ${__map_promote_keys})
    map_get(${__map_promote_map}  ${__map_promote_key})
    ans(__map_promote_value)
    set("${__map_promote_key}" "${__map_promote_value}" PARENT_SCOPE)
  endforeach()
endmacro()





  ## returns the length of the specified property
  function(map_property_length map prop)
    map_tryget("${map}" "${prop}")
    ans(val)
    list(LENGTH val len)
    return_ref(len)
  endfunction()


  macro(map_property_length map prop)
    get_property(__map_property_length_value GLOBAL PROPERTY "${map}.${prop}")
    list(LENGTH __map_property_length_value __ans)
  endmacro()


  macro(map_property_string_length map prop)
    get_property(__map_property_length_value GLOBAL PROPERTY "${map}.${prop}")
    string(LENGTH "${__map_property_length_value}" __ans)
  endmacro()






function(map_push_back map prop)
  map_tryget("${map}" "${prop}")
  ans(lst)
  list_push_back(lst ${ARGN})
  map_set("${map}" "${prop}" ${lst})
  return_ref(lst)
endfunction()





function(map_push_front map prop)
  map_tryget("${map}" "${prop}")
  ans(lst)
  list_push_front(lst ${ARGN})
  ans(res)
  map_set("${map}" "${prop}" ${lst})
  return_ref(res)
endfunction()





## renames a key in the specified map
function(map_rename map key_old key_new)
  map_get("${map}" "${key_old}")
  ans(value)
  map_remove("${map}" "${key_old}")
  map_set("${map}" "${key_new}" "${value}")
endfunction()






  function(map_set_if_missing map prop)
    map_has("${map}" "${prop}")
    if(__ans)
      return(false)
    endif()
    map_set("${map}" "${prop}")
    return(true)
  endfunction()





# converts a map to a key value list 
function(map_to_keyvaluelist map)
  map_keys(${map})
  ans(keys)
  set(kvl)
  foreach(key ${keys})
    map_get("${map}" "${key}")
    ans(val)
    list(APPEND kvl "${key}" "${val}")
  endforeach()
  return_ref(kvl)
endfunction()






  function(map_to_valuelist map)
    set(keys ${ARGN})
    list_extract_flag(keys --all)
    ans(all)
    if(all)
      map_keys(${map})
      ans(keys)
    endif()
    set(result)

    foreach(key ${keys})
      map_tryget(${map} "${key}")
      ans(value)
      list(APPEND result "${value}")
    endforeach()
    return_ref(result)
  endfunction()





  ## unpacks the specified reference to a map
  ## let a map be stored in the var 'themap'
  ## let it have the key/values a/1 b/2 c/3
  ## map_unpack(themap) will create the variables
  ## ${themap.a} contains 1
  ## ${themap.b} contains 2
  ## ${themap.c} contains 3
  function(map_unpack __ref)
    map_iterator(${${__ref}})
    ans(it)
    while(true)
      map_iterator_break(it)
      set("${__ref}.${it.key}" ${it.value} PARENT_SCOPE)
    endwhile()
  endfunction()




# returns all values of the map which are passed as ARNG
function(map_values this)
  set(args ${ARGN})
  if(NOT args)
    map_keys(${this})
    ans(args)
  endif()
  set(res)
	foreach(arg ${args})
		map_get(${this}  ${arg})
    ans(val)
		list(APPEND res ${val})	
	endforeach()
  return_ref(res)
endfunction()


# ## faster
# macro(map_values map)
#   set(__ans ${ARGN})
#   if(NOT __ans)
#     map_keys(${map})
#   endif()
#   ## ____map_values_key does not conflict as it is the loop variable
#   foreach(____map_values_key ${__ans})
#     map_tryget(${map} ${____map_values_key})
#     list(APPEND __map_values_result ${__ans})
#   endforeach()
#   set(__ans ${__map_values_result})
# endmacro()




## function which generates a map 
## out of the passed args 
## or just returns the arg if it is already valid
function(mm)
  
  set(args ${ARGN})
  # assignment
  list(LENGTH args len)
  if("${len}" GREATER 2)
    list(GET args 1 equal)
    list(GET args 0 target)
    if("${equal}" STREQUAL = AND "${target}" MATCHES "[a-zA-Z0-9_\\-]")
      list(REMOVE_AT args 0 )
      list(REMOVE_AT args 0 )
      mm(${args})
      ans(res)
      set("${target}" "${res}" PARENT_SCOPE)
      return_ref(res)
    endif()
  endif()



  data(${ARGN})
  return_ans()
endfunction()






## initializes a new mapiterator
  function(map_iterator map)
    map_keys("${map}")
    ans(keys)
    set(iterator "${map}" before_start ${keys})
    return_ref(iterator)    
  endfunction()






# use this macro inside of a while(true) loop it breaks when the iterator is over
# e.g. this prints all key values in the map
# while(true) 
#   map_iterator_break(myiterator)
#   message("${myiterator.key} = ${myiterator.value}")
# endwhile()
macro(map_iterator_break it_ref)
  map_iterator_next(${it_ref})
  if("${it_ref}.end")
    break()
  endif()
endmacro()




## this function moves the map iterator to the next position
## and returns true if it was possible
## e.g.
## map_iterator_next(myiterator) 
## ans(ok) ## is true if iterator had a next element
## variables ${myiterator.key} and ${myiterator.value} are available
macro(map_iterator_next it_ref)
  list(LENGTH "${it_ref}" __map_iterator_next_length)
  if("${__map_iterator_next_length}" GREATER 1)
    list(REMOVE_AT "${it_ref}" 1)
    if(NOT "${__map_iterator_next_length}" EQUAL 2)
      list(GET "${it_ref}" 1 "${it_ref}.key")
      list(GET "${it_ref}" 0 "__map_iterator_map")
      get_property("${it_ref}.value" GLOBAL PROPERTY "${__map_iterator_map}.${${it_ref}.key}")
      set(__ans true)
    else()
      set(__ans false)
      set("${it_ref}.end" true)
    endif() 
  else()
    set("${it_ref}.end" true)
    set(__ans false)
  endif()
endmacro()






function(map_check this)
	map_exists(${this} )
  ans(res)
	if(NOT ${res})
		message(FATAL_ERROR "map '${this}' does not exist")
	endif()
endfunction()






  function(map_decycle val)
    map_new()
    ans(visited_nodes)
    map_set(global ref_count 0)
    set(map_decycle_flatten true)
    function(decycle_successors result node)
      message("getting successors")
      
      is_map(${node} )
      ans(ismap)
      is_address(${node})
      ans(isref)
      set(potential_successors)
      if(ismap)
        map_keys(${node} )
        ans(keys)
        foreach(key ${keys})
          map_get(${node}  ${key} )
          ans(val)
          is_address(${val})
          ans(isref)
          if(isref)

            map_tryget(${visited_nodes}  "${val}")
            ans(ref_id)
            if(ref_id)
              set(val ${ref_id})
              map_set(${node} ${key} ${ref_id})
            endif()
          endif()

          list(APPEND potential_successors ${val})
        endforeach()
      elseif(isref)
        address_get(${node})
        ans(res)
        set(transformed_res)
        foreach(element ${res})
          is_address(${element})
          ans(isref)
          if(isref)
            map_tryget(${visited_nodes}  "${element}")
            ans(ref_id)
            if(ref_id)
              set(element ${ref_id})
            endif()
          endif()
          list(APPEND transformed_res ${element})
        endforeach()
        address_set(${node} "${transformed_res}")
        list(APPEND potential_successors ${res})
      endif()

      set(successors)  
      foreach(potential_successor ${potential_successors})
        is_address(${potential_successor})
        ans(isref)
        if(isref)
         # address_print(${visited_nodes})
          map_has(${visited_nodes} "${potential_successor}")
          ans(was_visited)
          if(NOT was_visited)
            list(APPEND successors ${potential_successor})
          
          endif()

          else()
        endif()
      endforeach()

      set(${result} ${successors} PARENT_SCOPE)
    endfunction()


    function(decycle_visit cancel value)
      message("visiting")
      is_map(${value} )
      ans(ismap)
      is_address(${value})
      ans(isref)
      if(isref)
        map_tryget(global ref_count)
        ans(ref_count)
        
        math(EXPR ref_count "${ref_count} + 1")
        map_set(global ref_count ${ref_count})
        map_set(${visited_nodes} ${value} "\$${ref_count}")   
        if(ismap)
          map_set(${value} "\$id" "\$${ref_count}")
          
        endif()


        message("found ref")
      endif()

    endfunction()

    map_graphsearch(VISIT decycle_visit SUCCESSORS decycle_successors ${val})

    #address_print(${visited_nodes})
    #address_print(${val})
  endfunction()




function(map_exists this )
	get_property(map_exists GLOBAL PROPERTY "${this}" SET)
  return(${map_exists})
endfunction()





function(map_format __input)
	format("${__input}")
	return_ans()
endfunction()




function(map_graphsearch)
	set(options)
  	set(oneValueArgs SUCCESSORS VISIT PUSH POP)
  	set(multiValueArgs)
  	set(prefix)
  	cmake_parse_arguments("${prefix}" "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  	#_UNPARSED_ARGUMENTS
  	# setup functions

  	if(NOT _SUCCESSORS)		
		function(gs_successors result node)
			#is_address(${node})
			#ans(isref)
			is_map( ${node} )
			ans(ismap)
			list_isvalid(${node}  )
			ans(islist)
			set(res)
			if(ismap)
				map_keys(${node} )
				ans(keys)
				map_values(${node}  ${keys})
				ans(res)
			elseif(islist)
				list_values(${node} )
				ans(values)
			endif()
			set(${result} "${res}" PARENT_SCOPE)
		endfunction()
	else()
		function_import("${_SUCCESSORS}" as gs_successors REDEFINE)
	endif()
	
	if(NOT _VISIT)
		function(gs_visit cancel value)
		endfunction()
	else()
		function_import("${_VISIT}" as gs_visit REDEFINE)
	endif()

	if(NOT _POP)
		function(gs_pop result)
			set(node)
			stack_peek(__gs)
			ans(node)
			if(NOT node)
				set(${result} PARENT_SCOPE)
				return()
			endif()
			stack_pop(__gs )
			ans(node)
			set(${result} "${node}" PARENT_SCOPE)
		endfunction()
	else()
		function_import("${_POP}" as gs_pop REDEFINE)
	endif()

	if(NOT _PUSH)
		function(gs_push node)
			stack_push(__gs ${node})
		endfunction()
	else()
		function_import("${_PUSH}" as gs_push REDEFINE)
	endif()

	# start of algorithm

	# add initial nodes to container
	foreach(node ${_UNPARSED_ARGUMENTS})
		gs_push(${node})
	endforeach()

	# iterate as long as there are nodes to visit
	while(true)
		set(current)
		# get first node
		gs_pop(current)
		if(NOT current)
			break()
		endif()

		set(cancel false)
		# visit node 
		# if cancel is set to true do not add successors
		gs_visit(cancel ${current})
		if(NOT cancel)
			gs_successors(successors ${current})
			foreach(successor ${successors})
				gs_push(${successor})
			endforeach()
		endif()
	endwhile()
endfunction()




## imports the specified properties into the current scope
## e.g map = {a:1,b:2,c:3}
## map_import_properties(${map} a c)
## -> ${a} == 1 ${b} == 2
macro(map_import_properties __map)
  foreach(key ${ARGN})
    map_tryget("${__map}" "${key}")
    ans("${key}")
  endforeach()
endmacro()






## returns true if actual has all properties (and recursive properties)
## that expected has
  function(map_match_obj actual expected)
    obj("${actual}")
    ans(actual)
    obj("${expected}")
    ans(expected)
    map_match("${actual}" "${expected}")
    return_ans()
  endfunction()




# orders the specified lst by applying the comparator
function(map_order _lst comparator)
	function_import("${comparator}" as map_sort_comparator REDEFINE)
	set(_i 0)
	set(_j 0)
	list(LENGTH ${_lst} _len)
	math(EXPR _len "${_len} -1")
	# slow sort
	while(true)
		if(NOT (${_i} LESS ${_len}))

			break()
		endif()
		list(GET ${_lst} ${_i} _a)
		list(GET ${_lst} ${_j} _b)
		map_sort_comparator(_res ${_a} ${_b})
		
		if(_res GREATER 0)
			list_swap(${_lst} ${_i} ${_j})
		endif()

		math(EXPR _j "${_j} + 1")
		if(${_j} GREATER ${_len})
			math(EXPR _i "${_i} + 1")
			math(EXPR _j "${_i} + 1")
		endif()

	endwhile()
	
	set(${_lst} ${${_lst}} PARENT_SCOPE)
endfunction()




# prints all values of the map
function(map_print this)
	map_keys(${this} )
  ans(keys)
	foreach(key ${keys})
		map_get(${this}   ${key})
    ans(value)
		message("${key}: ${value}")
	endforeach()
endfunction()




function(map_print_format)
	map_format( "${ARGN}")
  ans(res)
	message("${res}")

endfunction()




function(map_query query)
	# get definitions
	string(STRIP "${query}" query)
	set(regex "(from .* in .*(,.* in .*)*)((where).*)")
	string(REGEX REPLACE "${regex}" "\\1" sources "${query}")

	# get query
	string(LENGTH "${sources}" len)
	string(SUBSTRING "${query}" ${len} -1 query)
	string(STRIP "${query}" query)


	# get query predicate and selection term
	string(REGEX REPLACE "where(.*)select(.*)" "\\1" where "${query}")
	string(REGEX REPLACE "where(.*)select(.*)" "\\2" select "${query}")
	string(STRIP "${where}" where)
	string(STRIP "${select}" select)
	string_split( "${where}" " ")
	ans(where_parts)

	#remove "from " from sources
	string(SUBSTRING "${sources}" 5 -1 sources)



	# callback function for map_foreach
	function(map_query_foreach_action)
		#print_locals()
		#message("${where_parts} = ${installed_pkg} + ${dependency_pkg}")
		map_format( "${where_parts}")
		ans(current_where)
		# return value
		if(${current_where})
			map_transform( "${select}")
			ans(selection)
			address_append(${map_query_result} "${selection}")
		endif()

	endfunction()

	# create a ref where the result is stored
	address_new()
	ans(map_query_result)
	map_foreach(map_query_foreach_action "${sources}")
	
	# get the result
	address_get(${map_query_result} )
	ans(res)
	address_delete(${map_query_result})

	return_ref(res)
	
endfunction()




 # todo: complete
 function(map_restore_refs ref)
    map_new()
    ans(ref_ids)

    function(map_restore_find_refs cancel node)
      is_address(${node})
      ans(isref)
      is_map(${node})
      ans(ismap)

      if(ismap)
        map_tryget(${node}  "$id")
        ans(id)
        if(id)
          map_set(${ref_ids} "${id}" ${node})
        endif()
      endif()
    endfunction()
    function(map_restore_restore_refs cancel node)

    endfunction()

    # find refs
    map_graphsearch(VISIT map_restore_find_refs ${ref})
    map_graphsearch(VISIT map_restore_restore_refs ${ref})

    
    #restore refs
   # map_print(${ref_ids})
   # map_print(${ref})
  endfunction()




function(map_select  query)
# select something from a list 
# using syntax 'from a in lstA, b in lstB select {a.k1}{b.k1}'
# see map_transform and map_foreach
	string(REGEX REPLACE "from(.*)select(.*)" "\\1" _foreach_args "${query}")
	string(REGEX REPLACE "from(.*)select (.*)" "\\2" _select_args "${query}")

	list_new()
	ans(_result_list)
	function(_map_select_foreach_action)
		map_transform( "${_select_args}")
		ans(res)
		address_append(${_result_list} "${res}")
	endfunction()
	map_foreach( _map_select_foreach_action "${_foreach_args}")
	address_get( ${_result_list} )
	ans(_result_list)
	return_ref(_result_list)

endfunction()

function(map_select_property)

	endfunction()




function(map_transform  query)
	string(STRIP "${query}" query)
	string(FIND "${query}" "new" res)
	if(${res} EQUAL 0)

		string(SUBSTRING "${query}" 3 -1 query)
		json_deserialize( "${query}")
		ans(obj)

		function(map_select_visitor)
			list_isvalid(${current} )
			ans(islist)
			is_map(${current} )
			ans(ismap)
			if(islist)
				address_get(${current} )
				ans(values)
				set(transformed_values)
				foreach(value ${values})
					map_format( "${value}")
					ans(res)
					set(transformed_values "${transformed_values}" "${value}")
				endforeach()
				address_set(${current} "${transformed_values}")
			elseif(ismap)
				map_keys(${current} )
				ans(keys)
				foreach(key ${keys})
					map_get(${current}  ${key})
					ans(value)
					map_format( "${value}")
					ans(res)
					map_set(${current} ${key} "${res}")
				endforeach()
			endif()
		endfunction()
		map_graphsearch(${obj} VISIT map_select_visitor)
		return_ref(obj)
	endif()

	set(res)
	map_format( "${query}")
	ans(res)
	return_ref(res)
endfunction()




# query a a list of maps with linq like syntax
# ie  from package in packages where package.id STREQUAL package1 AND package.version VERSION_GREATER 1.3
# packages is a list of maps and package is the name for a single pakcage used in the where clause
# 
function(map_where  query)
	set(regex "from (.*) in (.*) where (.*)")
	string(REGEX REPLACE "${regex}" "\\1" ref "${query}")
	string(REGEX REPLACE "${regex}" "\\2" source "${query}")
	string(REGEX REPLACE "${regex}" "\\3" where "${query}")
	string_split( "${where}" " ")
	ans(where_parts)
	set(res)
	foreach(${ref} ${${source}})
		map_format( "${where_parts}")
		ans(current_where)
		if(${current_where})
			set(res ${res} ${${ref}})
		endif()
	endforeach()	 
	return_ref(res)
endfunction()





function(map_clone original type) 
  if("${type}" STREQUAL "DEEP")
    map_clone_deep("${original}")
    return_ans()
  elseif("${type}" STREQUAL "SHALLOW") 
    map_clone_shallow("${original}")
    return_ans()
  else()
    message(FATAL_ERROR "unknown clone type: ${type}")
  endif()
endfunction()





function(map_clone_deep original)
  map_clone_shallow("${original}")
  ans(result)
    
  is_map("${result}" )
  ans(ismap)
  if(ismap) 
    map_keys("${result}" )
    ans(keys)
    foreach(key ${keys})
      map_get(${result}  ${key})
      ans(value)
      map_clone_deep("${value}")
      ans(cloned_value)
      map_set(${result} ${key} ${cloned_value})
    endforeach()
  endif()
  return_ref(result)
endfunction()





function(map_clone_shallow original)
  is_map("${original}" )
  ans(ismap)
  if(ismap)
    map_new()
    ans(result)
    map_keys("${original}" )
    ans(keys)
    foreach(key ${keys})
      map_get("${original}"  "${key}")
      ans(value)
      map_set("${result}" "${key}" "${value}")
    endforeach()
    return(${result})
  endif()

  is_address("${original}")
  ans(isref)
  if(isref)
    address_get(${original})
    ans(res)
    address_type_get(${original})
    ans(type)
    address_new(${type})
    ans(result)
    address_set(${result} ${res})
    return(${result})
  endif()

  # everythign else is a value type and can be returned
  return_ref(original)

endfunction()






# compares two maps and returns true if they are equal
# order of list values is important
# order of map keys is not important
# cycles are respected.
function(map_equal lhs rhs)
	# create visited map on first call
	set(visited ${ARGN})
	if(NOT visited)
		map_new()
		ans(visited)
	endif()

	# compare lengths of lhs and rhs return false if they are not equal
	list(LENGTH lhs lhs_length)
	list(LENGTH rhs rhs_length)

	if(NOT "${lhs_length}" EQUAL "${rhs_length}")
		return(false)
	endif()


	# compare each element of list recursively and return result
	if("${lhs_length}" GREATER 1)
		math(EXPR len "${lhs_length} - 1")
		foreach(i RANGE 0 ${len})
			list(GET lhs "${i}" lhs_item)
			list(GET rhs "${i}" rhs_item)
			map_equal("${lhs_item}" "${rhs_item}" ${visited})
			ans(res)
			if(NOT res)
				return(false)
			endif()
		endforeach()
		return(true)
	endif()

	# compare strings values of lhs and rhs and return if they are equal
	if("${lhs}" STREQUAL "${rhs}")
		return(true)
	endif()

	# else lhs and rhs might be maps
	# if they are not return false
	is_map(${lhs})
	ans(lhs_ismap)

	if(NOT lhs_ismap)
		return(false)
	endif()

	is_map(${rhs})	
	ans(rhs_ismap)

	if(NOT rhs_ismap)
		return(false)
	endif()

	# if already visited return true as a parent call will correctly 
	# determine equality
	map_tryget(${visited} ${lhs})
	ans(lhs_isvisited)
	if(lhs_isvisited)
		return(true)
	endif()

	map_tryget(${visited} ${rhs})
	ans(rhs_isvisited)
	if(rhs_isvisited)
		return(true)
	endif()

	# set visited to true
	map_set(${visited} ${lhs} true)
	map_set(${visited} ${rhs} true)

	# compare keys of lhs and rhs	
	map_keys(${lhs} )
	ans(lhs_keys)
	map_keys(${rhs} )
	ans(rhs_keys)

	# order not important
	set_isequal(lhs_keys rhs_keys)
	ans(keys_equal)

	if(NOT keys_equal)		
		return(false)
	endif()

	# compare each property of lhs and rhs recursively
	foreach(key ${lhs_keys})

		map_get(${lhs}  ${key})
		ans(lhs_property_value)
		map_get(${rhs}  ${key})
		ans(rhs_property_value)
		
		map_equal("${lhs_property_value}" "${rhs_property_value}" ${visited})		
		ans(val_equal)
		if(NOT val_equal)
			return(false)
		endif()
	endforeach()

	## everything is equal -> return true
	return(true)
endfunction()






## compares two maps for value equality
## lhs and rhs may be objectish 
function(map_equal_obj lhs rhs)
  obj("${lhs}")
  ans(lhs)
  obj("${rhs}")
  ans(rhs)
  map_equal("${lhs}" "${rhs}")
  return_ans()
endfunction()




# executes action (key, value)->void
# on every key value pair in map
# exmpl: map = {id:'1',val:'3'}
# map_foreach("${map}" "(k,v)-> message($k $v)")
# prints 
#  id;1
#  val;3
function(map_foreach map action)
	map_keys("${map}")
	ans(keys)
	foreach(key ${keys})
		map_tryget("${map}" "${key}")
		ans(val)
		call("${action}"("${key}" "${val}"))
	endforeach()
endfunction()




function(map_issubsetof result superset subset)
	map_keys(${subset} )
	ans(keys)
	foreach(key ${keys})
		map_tryget(${superset}  ${key})
		ans(superValue)
		map_tryget(${subset}  ${key})
		ans(subValue)

		is_map(${superValue} )
		ans(issupermap)
		is_map(${subValue} )
		ans(issubmap)
		if(issubmap AND issubmap)
			map_issubsetof(res ${superValue} ${subValue})
			if(NOT res)
				return_value(false)
			endif()
		else()
			list_isvalid(${superValue} )
			ans(islistsuper)
			list_isvalid(${subValue} )
			ans(islistsub)
			if(islistsub AND islistsuper)
				address_get(${superValue})
				ans(superValue)
				address_get(${subValue})
				ans(subValue)
			endif()
			list_equal( "${superValue}" "${subValue}")
			ans(res)
			if(NOT res)
				return_value(false)
			endif()
		endif()
	endforeach()
	return_value(true)
endfunction()




# creates a union from all all maps passed as ARGN and combines them in result
# you can merge two maps by typing map_union(${map1} ${map1} ${map2})
# maps are merged in order ( the last one takes precedence)
function(map_merge )
	set(lst ${ARGN})

	map_new()
  ans(res)
  
	foreach(map ${lst})
		map_keys(${map} )
		ans(keys)
		foreach(key ${keys})
			map_tryget(${res}  ${key})
			ans(existing_val)
			map_tryget(${map}  ${key})
			ans(val)

			is_map("${existing_val}" )
			ans(existing_ismap)
			is_map("${val}" )
			ans(new_ismap)

			if(new_ismap AND existing_ismap)
				map_union(${existing_val}  ${val})
				ans(existing_val)
			else()
				
				map_set(${res} ${key} ${val})
			endif()
		endforeach()
	endforeach()
	return(${res})
endfunction()






# creates a union from all all maps passed as ARGN and combines them in the first
# you can merge two maps by typing map_union(${map1} ${map1} ${map2})
# maps are merged in order ( the last one takes precedence)
function(map_union)
	set(lst ${ARGN})
	list_pop_front(lst)
	ans(res)
	if(NOT res)
		message(FATAL_ERROR "map_union: no maps passed")
	endif()
	# loop through the keys of every map	
	foreach(map ${lst})
		map_keys(${map} )
		ans(keys)
		foreach(key ${keys})
			map_tryget(${map}  ${key})
			ans(val)
			map_set(${res} ${key} ${val})
		endforeach()
	endforeach()
	return(${res})
endfunction()






## `([!]<expr> <value>|("="|"+=" <expr><call>)) -> <any>`
##
## the assign function allows the user to perform some nonetrivial 
## operations that other programming languages allow 
##
## Examples
## 
  function(assign __lvalue __operation __rvalue)    
    ## is a __value

    if(NOT "${__operation}" MATCHES "^(=|\\+=)$" )
      ## if no equals sign is present then interpret all
      ## args as a simple literal cmake value
      ## this allows the user to set an expression to 
      ## a complicated string with spaces without needing
      ## to single quote it
      set(__value ${__operation} ${__rvalue} ${ARGN})
    elseif("${__rvalue}" MATCHES "^'.*'$")
      string_decode_delimited("${__rvalue}" ')
      ans(__value)
    elseif("${__rvalue}" MATCHES "(^{.*}$)|(^\\[.*\\]$)")
      script("${__rvalue}")
      ans(__value)
    else()
      navigation_expression_parse("${__rvalue}")
      ans(__rvalue)
      list_pop_front(__rvalue)
      ans(__ref)

      if("${ARGN}" MATCHES "^\\(.*\\)$")
        ref_nav_get("${${__ref}}" "&${__rvalue}")
        ans(__value)

        map_tryget(${__value} ref)
        ans(__value_ref)

        data("${ARGN}")
        ans(__args)
        if(NOT __value_ref)
          call("${__ref}" ${__args})
          ans(__value)
      
        else()
          map_tryget(${__value} property)
          ans(__prop)
          map_tryget(${__value} range)
          ans(ranges)

          if(NOT ranges)
            list_pop_front(__args)
            list_pop_back(__args)
            obj_member_call("${__value_ref}" "${__prop}" ${__args})
            ans(__value)

          else()
            map_tryget(${__value} __value)
            ans(__callables)
            set(__value)
            set(this "${__value_ref}")
            foreach(__callable ${__callables})
              call("${__callable}" ${__args})
              ans(__res)
              list(APPEND __value ${__res})
            endforeach()
          endif()
        endif()
      else()      
        ref_nav_get("${${__ref}}" ${__rvalue})
        ans(__value)
      endif()
    endif()
    string_take(__lvalue !)
    ans(__exc)
    navigation_expression_parse("${__lvalue}")
    ans(__lvalue)
    list_pop_front(__lvalue)
    ans(__lvalue_ref)

    if("${__operation}" STREQUAL "+=")
      ref_nav_get("${${__lvalue_ref}}" "${__lvalue}")
      ans(prev_value)
      set(__value "${prev_value}${__value}")
    endif()
   # message("ref_nav_set ${${__lvalue_ref}} ${__exc}${__lvalue} ${__value}" )
    ref_nav_set("${${__lvalue_ref}}" "${__exc}${__lvalue}" "${__value}")
    ans(__value)
    set(${__lvalue_ref} ${__value} PARENT_SCOPE)
    return_ref(__value)
  endfunction()





  ## universal get function which allows you to get
  ## from an object or map. only allows property names
  ## returns nothing if navigting the object tree fails
  function(get ref_name _equals nav)
    string(REPLACE "." "\;" nav "${nav}")
    set(nav ${nav})
    list_pop_front(nav)
    ans(part)


    set(current "${${part}}")
    map_get_special("${current}" object)
    ans(isobject)

    if(isobject)
      foreach(part ${nav})
        obj_get("${current}" "${part}")
        ans(current)
        if("${current}_" STREQUAL "_")
          break()
        endif()
      endforeach()
    else()
      foreach(part ${nav})
        map_tryget("${current}" "${part}")
        ans(current)
        if("${current}_" STREQUAL "_")
          break()
        endif()
      endforeach()
    endif()
    
    set("${ref_name}" "${current}" PARENT_SCOPE)
  endfunction()




#navigates a map structure
# use '.' and '[]' operators to select next element in map
# e.g.  map_navigate(<map_ref> res "propa.propb[3].probc[3][4].propd")
function(map_navigate result navigation_expression)
	# path is empty => ""
	if(navigation_expression STREQUAL "")
		return_value("")
	endif()

	# if navigation expression is a simple var just return it
	if("${navigation_expression}")
		return_value(${${navigation_expression}})
	endif()

	# check for dereference operator
	set(deref false)
	if("${navigation_expression}" MATCHES "^\\*")
		set(deref true)
		string(SUBSTRING "${navigation_expression}" 1 -1 navigation_expression)
	endif()

	# split off reference from navigation expression
	unset(ref)
	#_message("${navigation_expression}")
	string(REGEX MATCH "^[^\\[|\\.]*" ref "${navigation_expression}")
	string(LENGTH "${ref}" len )
	string(SUBSTRING "${navigation_expression}" ${len} -1 navigation_expression )

	

	# if ref is a ref to a ref dereference it :D 
	set(not_defined true)
	if(DEFINED ${ref})
		set(ref ${${ref}})
		set(not_defined false)
	endif()

	# check if ref is valid
	is_address("${ref}")
	ans(is_ref)
	if(NOT is_ref)
		if(not_defined)
			return_value()
		endif()
		set(${result} "${ref}" PARENT_SCOPE)

		return()
		message(FATAL_ERROR "map_navigate: expected a reference but got '${ref}'")
	endif()

	# match all navigation expression parts
	string(REGEX MATCHALL  "(\\[([0-9][0-9]*)\\])|(\\.[a-zA-Z0-9_\\-][a-zA-Z0-9_\\-]*)" parts "${navigation_expression}")
	
	# loop through parts and try to navigate 
	# if any part of the path is invalid return ""
	set(current "${ref}")
	foreach(part ${parts})
		string(REGEX MATCH "[a-zA-Z0-9_\\-][a-zA-Z0-9_\\-]*" index "${part}")
		string(SUBSTRING "${part}" 0 1 index_type)	
		if(index_type STREQUAL ".")
			# get by key
			map_tryget(${current}  "${index}")
			ans(current)
		elseif(index_type STREQUAL "[")
			message(FATAL_ERROR "map_navigate: indexation '[<index>]' is not supported")
			# get by index
			address_get( ${current} )
			ans(lst)
			list(GET lst ${index} keyOrValue)
			map_tryget(${current}  ${keyOrValue})
			ans(current)
			if(NOT current)
				set(current "${keyOrValue}")
			endif()
		endif()
		if(NOT current)
			return_value("${current}")
		endif()
	endforeach()
	if(deref)
		is_address("${current}"  )
		ans(is_ref)
		if(is_ref)
			address_get("${current}" )
			ans(current)
		endif()
	endif()
	# current  contains the navigated value
	set(${result} "${current}" PARENT_SCOPE)
endfunction()
	





function(map_navigate_set navigation_expression)
	cmake_parse_arguments("" "FORMAT" "" "" ${ARGN})
	set(args)
	if(_FORMAT)
		foreach(arg ${_UNPARSED_ARGUMENTS})
			map_format( "${arg}")
			ans(formatted_arg)
			list(APPEND args "${formatted_arg}")
		endforeach()
	else()
		set(args ${_UNPARSED_ARGUMENTS})
	endif()
	# path is empty => ""
	if(navigation_expression STREQUAL "")
		return_value("")
	endif()

	# split off reference from navigation expression
	unset(ref)
	string(REGEX MATCH "^[^\\[|\\.]*" ref "${navigation_expression}")
	string(LENGTH "${ref}" len )
	string(SUBSTRING "${navigation_expression}" ${len} -1 navigation_expression)

	# rest of navigation expression is empty, first is a var
	if(NOT navigation_expression)

		set(${ref} "${args}" PARENT_SCOPE)
		return()
	endif()
	



	# match all navigation expression parts
	string(REGEX MATCHALL  "(\\[([0-9][0-9]*)\\])|(\\.[a-zA-Z0-9_\\-][a-zA-Z0-9_\\-]*)" parts "${navigation_expression}")
	
	# loop through parts and try to navigate 
	# if any part of the path is invalid return ""

	set(current "${${ref}}")
	
	
	while(parts)
		list(GET parts 0 part)
		list(REMOVE_AT parts 0)
		
		string(REGEX MATCH "[a-zA-Z0-9_\\-][a-zA-Z0-9_\\-]*" index "${part}")
		string(SUBSTRING "${part}" 0 1 index_type)	



		#message("current ${current}, parts: ${parts}, current_part: ${part}, current_index ${index} current_type : ${index_type}")
		# first one could not be ref so create ref and set output
		is_address("${current}")
		ans(isref)
		
		if(NOT isref)
			map_new()
    	ans(current)
			set(${ref} ${current} PARENT_SCOPE)
		endif()		
		
		# end of navigation string reached, set value
		if(NOT parts)
			map_set(${current} ${index} "${args}")
			return()
		endif()

		
		map_tryget(${current}  "${index}")
		ans(next)
		# create next element in change
		if(NOT next)
			map_new()
    	ans(next)
			map_set(${current} ${index} ${next})
		endif()

		# if no next element exists its an error
		if(NOT next)
			message(FATAL_ERROR "map_navigate_set: path is invalid")
		endif()

		set(current ${next})

		
	endwhile()
endfunction()






function(map_navigate_set_if_missing navigation_expr)
  map_navigate(result ${navigation_expr})
  if(NOT result OR "${result}" STREQUAL "${navigation_expr}")
    map_navigate_set("${navigation_expr}" ${ARGN})
  endif() 
endfunction()




# a convenience function for navigating maps
# nav(a.b.c) -> returns memver c of member b of map a
# nav(a.b.c 3) ->sets member c of member b of map a to 3 (creating any missing maps along the way)
# nav(a.b.c = d.e.f) -> assignes the value of d.e.f to a.b.c
# nav(a.b.c += d.e) adds the value of d.e to the value of a.b.c
# nav(a.b.c -= d.e) removes the value of d.e from a.b.c
# nav(a.b.c FORMAT "{d.e}@{d.f}") formats the string and assigns a.b.c to it
# nav(a.b.c CLONE_DEEP d.e.f) clones the value of d.e.f depely and assigns it to a.b.c
function(nav navigation_expression)
  set(args ${ARGN})
  if("${args}_" STREQUAL "_")
    map_navigate(res "${navigation_expression}")
    return(${res})
  endif()

  if("${ARGN}" STREQUAL "UNSET")
    map_navigate_set("${navigation_expression}")
    return()
  endif()


  set(args ${ARGN})
  list_peek_front(args)
  ans(first)

  if("_${first}" STREQUAL _CALL)
    call(${args})
    ans(args)
  elseif("_${first}" STREQUAL _FORMAT)
    list_pop_front( args)
    map_format("${args}")  
    ans(args)
  elseif("_${first}" STREQUAL _APPEND OR "_${first}" STREQUAL "_+=")
    list_pop_front(args)
    map_navigate(cur "${navigation_expression}")
    map_navigate(args "${args}")
    set(args ${cur} ${args})
  elseif("_${first}" STREQUAL _REMOVE OR "_${first}" STREQUAL "_-=")
    list_pop_front(args)
    map_navigate(cur "${navigation_expression}")
    map_navigate(args "${args}")
    if(cur)
      list(REMOVE_ITEM cur "${args}")
    endif()
    set(args ${cur})
 elseif("_${first}" STREQUAL _ASSIGN OR "_${first}" STREQUAL _= OR "_${first}" STREQUAL _*)
    list_pop_front( args)
    map_navigate(args "${args}")
    
 elseif("_${first}" STREQUAL _CLONE_DEEP)
    list_pop_front( args)
    map_navigate(args "${args}")
    map_clone_deep("${args}")
    ans(args)
 elseif("_${first}" STREQUAL _CLONE_SHALLOW)
    list_pop_front( args)
    map_navigate(args "${args}")
    map_clone_shallow("${args}")
    ans(args)
  endif()

  # this is a bit hacky . if a new var is created by map_navigate_set
  # it is propagated to the PARENT_SCOPE
  string(REGEX REPLACE "^([^.]*)\\..*" "\\1" res "${navigation_expression}")
  map_navigate_set("${navigation_expression}" ${args})
  set(${res} ${${res}} PARENT_SCOPE)

  return_ref(args)
endfunction()




function(navigation_expression_parse)
    string(REPLACE "." ";" expression "${ARGN}")
    string(REPLACE "[" "<" expression "${expression}" )
    string(REPLACE "]" ">" expression "${expression}" )
    string(REGEX REPLACE "([<>][0-9:-]*[<>])" ";\\1" expression "${expression}")
    string(REGEX REPLACE "^;" "" expression "${expression}")
    return_ref(expression)
  endfunction()





  ## `(<clause:{<selector>:<literal...>}> <any..> )-><bool>`
  ##
  ## queries the specified args for the specified clause
  function(query_disjunction clause)
    map_keys("${clause}")
    ans(selectors)

    foreach(selector ${selectors})
      map_tryget(${clause} "${selector}")
      ans(predicates)

      foreach(predicate ${predicates})

        if("${selector}" STREQUAL " ")
          set(selector)
          set(foreach_item false)
        elseif("${selector}" MATCHES "(.*)\\[.*\\]$")
          set(foreach_item true)
          set(target_property ${CMAKE_MATCH_1})
        else()
          set(foreach_item false)
        endif()


        ref_nav_get("${ARGN}" ${selector})
        ans(value)

        query_literal("${predicate}" __query_predicate)
        ans(success)

        if(success)
          if(foreach_item)
            foreach(item ${value})
              __query_predicate(${item})
              if(__ans)
                return(true)
              endif()
            endforeach()
          else()
            __query_predicate(${value})
            if(__ans)
              return(true)
            endif()
          endif()
        endif()
      endforeach()
    endforeach()

    return(false)
  endfunction()






function(query_literal)


  query_literal_definition_add(bool query_literal_bool "^((true)|(false))$")
  query_literal_definition_add(regex query_literal_regex "^/(.+)/$")
  query_literal_definition_add(gt query_literal_gt "^>([^=].*)")
  query_literal_definition_add(lt query_literal_lt "^<([^=].*)")
  query_literal_definition_add(eq query_literal_eq "^=([^=].*)")
  query_literal_definition_add(match query_literal_match "^\\?/(.+)/$" )
  query_literal_definition_add(strequal  query_literal_strequal "(.+)")  
  query_literal_definition_add(where query_literal_where "" )

    
  function(query_literal query_literal_instance )
    if("${query_literal_instance}_" STREQUAL "_")
      return()
    endif()

    is_address("${query_literal_instance}")
    ans(is_ref)

    if(is_ref)
      map_keys(${query_literal_instance})
      ans(type)
      query_literal_definition("${type}")
      ans(query_literal_definition)
      map_tryget(${query_literal_instance} "${type}")
      ans(query_literal_input)
    else()
      # is predicate?
      if(false)
        
      else()
        query_literal_definitions_with_regex()
        ans(definitions)
        foreach(def ${definitions})
          map_tryget(${def} regex)
          ans(regex)
          set(query_literal_input)
          if("${query_literal_instance}" MATCHES "${regex}")
            set(query_literal_input ${CMAKE_MATCH_1})
          endif()
        #   print_vars(query_literal_input query_literal_instance regex replace)
          if(NOT "${query_literal_input}_" STREQUAL "_")
            set(query_literal_definition ${def})
            break()
          endif()
        endforeach()

        # if("${query_literal_instance}" MATCHES "^(true)|(false)$")
        #   ## boolish
        #   map_new()
        #   ans(query_literal_definition)
        #   map_set(${query_literal_definition} bool ${query_literal_instance})
        # else()
        #   ## just a value -> strequal
        #   map_new()
        #   ans(query_literal_definition)
        #   map_set(${query_literal_definition} strequal ${query_literal_instance})
        # endif()
      endif()
    endif()
    if(NOT query_literal_definition)
      message(FATAL_ERROR "invalid query literal")
    endif()

    map_tryget(${query_literal_definition} function)
    ans(query_literal_function)

    if("${ARGN}_" STREQUAL "_")
      function_new()
      ans(alias)
    else()
      set(alias ${ARGN})
    endif()

    ## create a curried function
    eval( "
    function(${alias})
      ${query_literal_function}(\"${query_literal_input}\" \${ARGN})
      set(__ans \${__ans} PARENT_SCOPE)
    endfunction()
    ")
    return_ref(alias)
  endfunction()

  query_literal(${ARGN})
  return_ans()
endfunction()





  function(query_literal_bool expected)
    #message("bool ${expected} - ${ARGN}")
    if(ARGN AND expected)
      return(true)
    elseif(NOT ARGN AND NOT expected)
      return(true)
    endif()
    return(false)
  endfunction()






  function(query_literal_eq input)
    if("${ARGN}" EQUAL "${input}")
      return(true)
    endif()
    return(false)
  endfunction()







  function(query_literal_gt input)
    if("${ARGN}" GREATER "${input}")
      return(true)
    endif()
    return(false)
  endfunction()






  function(query_literal_lt input)
    if("${ARGN}" LESS "${input}")
      return(true)
    endif()
    return(false)
  endfunction()






  function(query_literal_match expected)
    #message("match ${expected} - ${ARGN}")
    if("${ARGN}" MATCHES "${expected}")
      return(true)
    endif()
    return(false)
  endfunction()






  function(query_literal_regex input)
    is_address("${input}")
    ans(is_ref)
    if(is_ref)
      map_import_properties(${input} 
        match
        matchall
        replace
      )
    else()  
      set(match "${input}")
      set(matchall)
    endif()
    if(NOT replace )
      set(replace "$0")
    endif()

    if(NOT "${match}_" STREQUAL "_")
      regex_match_replace("${match}" "${replace}" "${ARGN}")
      ans(result)
      return_ref(result)
    elseif(NOT "${matchall}_" STREQUAL "_")
      string(REGEX MATCHALL "${matchall}" matches "${ARGN}")
      set(result)
      foreach(match ${matches})
        regex_match_replace("${matchall}" "${replace}" "${match}")
        ans_append(result)
      endforeach()
      return_ref(result)
    else()
      message(FATAL_ERROR "no regex speciefied (either match or matchall property needs to be set)")
    endif()
    return()
  endfunction()






  function(query_literal_strequal expected)
    #message("strequal ${expected} - ${ARGN}")
    if("${expected}_" STREQUAL "${ARGN}_")
      return(true)
    endif()
    return(false)
  endfunction()





  function(query_literal_where input)
    query_literal("${input}" __query_literal_select_predicate)
    ans(success)

    if(NOT success)
      return()
    endif()

    __query_literal_select_predicate(${ARGN})
    ans(match)
    if(match)
      set(result ${ARGN})
      return_ref(result)
    endif()
    return()
  endfunction()





  function(query_literal_definition_add type function regex)
    map_new()
    ans(query_literal_def)
    callable_function("${function}")
    ans(function)
    map_set(${query_literal_def} type "${type}")
    map_set(${query_literal_def} function "${function}")
    if(regex)
      map_set(${query_literal_def} regex "${regex}")
      address_append(__query_literal_handlers_with_regex ${query_literal_def})
    endif()
    map_set(__query_literal_handlers "${type}" "${query_literal_def}")
    return_ref(query_literal_def)
  endfunction()

macro(query_literal_definitions_with_regex)
  address_get(__query_literal_handlers_with_regex)
endmacro()
macro(query_literal_definitions)
  map_value(__query_literal_handlers)
endmacro() 

function(query_literal_definition_function type)
  map_tryget(__query_literal_handlers "${type}")
  ans(handler)
  map_tryget("${handler}" function )
  return_ans()

endfunction()

macro(query_literal_definition type)
  map_tryget(__query_literal_handlers "${type}")
endmacro()




##  `(<clauses: <clause: { <selector>:<literal...> }>...> <any...>)-><bool>`
## 
##  queries the specified args for the specified clauses in conjunctive normal form
function(query_match_cnf clauses)
  data("${clauses}")
  ans(clauses)

  foreach(clause ${clauses})
    query_disjunction(${clause} ${ARGN})
    ans(clause_result)
    if(NOT clause_result)
      return(false)
    endif()
  endforeach()
  return(true)
endfunction()





## `(<query: { <<selector:<navigation expression>> : <query literal>>...  } > <any>)-><any>`
##
## selects values depending on the specified query
## example 
## ```
## assign(input_data = "{
##   a: 'hello world',
##   b: 'goodbye world',
##   c: {
##    d: [1,2,3,4,5]
##   } 
## }")
## assign(result = query_selection("{a:{regex:{matchall:'[^ ]+'}}" ${input_data}))
## assertf("{result.a}" EQUALS  "hello" "world")
##
## ```
function(query_selection query)
  obj("${query}")


  map_keys("${query}")
  ans(selectors)



  set(result)


  ## loop through all selectors
  foreach(selector ${selectors})
    map_tryget(${query} "${selector}")
    ans(literal)

    ## check to see if selector ends with [...] 
    ## which indicates that action should be performed
    ## foreach item 
    ## 
    set(target_property)

    if("${selector}" MATCHES "(.+)=>(.+)")
      set(selector "${CMAKE_MATCH_1}")
      set(target_property "${CMAKE_MATCH_2}")
    endif()

    if("${selector}" STREQUAL "$")
      set(selector)
      set(foreach_item false)
    elseif("${selector}" MATCHES "(.*)\\[.*\\]$")
      if(NOT "${selector}" MATCHES "\\[-?([0]|[1-9][0-9]*)\\]$")
        if(NOT target_property)
          set(target_property "${CMAKE_MATCH_1}")
        endif()
        set(foreach_item true)
      endif()
    else()
      set(foreach_item false)
    endif()

    if("${target_property}_" STREQUAL "_")
      set(target_property "${selector}")
    endif()
    if("${target_property}" STREQUAL "$")
      set(target_property)
    endif()


    ref_nav_get("${ARGN}" ${selector})
    ans(value)

    query_literal("${literal}" __query_literal)
    ans(success)

    if(success)
      set(selection)
      if(foreach_item)
        foreach(item ${value})
          __query_literal(${item})
          if(NOT "${__ans}_" STREQUAL "_" )
            list(APPEND selection ${__ans})
          endif()
        endforeach()
      else()
        __query_literal(${value})
        if(NOT "${__ans}_" STREQUAL "_" )
          list(APPEND selection ${__ans})
        endif()
      endif()
      ref_nav_set("${result}" "!${target_property}" ${selection})
      ans(result)
    endif()

  endforeach()
  return_ref(result)

endfunction()




##
##
##
function(query_where query)
  data("${query}")
  ans(query)

  map_keys("${query}")
  ans(selectors)

  set(result)

  foreach(selector ${selectors})
    map_tryget(${query} "${selector}")
    ans(predicate)

    if("${selector}" STREQUAL " ")
      set(selector)
      set(foreach_item false)
    elseif("${selector}" MATCHES "(.*)\\[.*\\]$")
      set(foreach_item true)
      set(target_property ${CMAKE_MATCH_1})
    else()
      set(foreach_item false)
    endif()

    ref_nav_get("${ARGN}" ${selector})
    ans(value)

    query_literal("${predicate}" __query_predicate)
    ans(success)

    if(success)
      set(matched_values)
      set(found_match false)
      if(foreach_item)
        foreach(item ${value})
          __query_predicate(${item})
          if(__ans)
            list(APPEND matched_values ${item})
            set(found_match true)
          endif()
        endforeach()
      else()
        __query_predicate(${value})
        if(__ans)
          list(APPEND matched_values ${value})
          set(found_match true)
        endif()
      endif()

      if(found_match)
        ref_nav_set("${result}" "!${target_property}" ${matched_values})
        ans(result)
      endif()
    endif()

  endforeach()

  return_ref(result)

endfunction()







  function(ref_keys ref)
    map_get_special("${ref}" object)
    ans(isobject)
    if(isobject)
      obj_keys("${ref}")
    else()
      map_keys("${ref}")
    endif()
    return_ans()
  endfunction()






  function(ref_nav_create_path expression)
    navigation_expression_parse("${expression}")
    ans(expression)
    set(current_value ${ARGN})
    while(true)
      list(LENGTH expression continue)
      if(NOT continue)
        break()
      endif()

      list_pop_back(expression)
      ans(current_expression)
      if(NOT "${current_expression}" STREQUAL "[]")
        if("${current_expression}" MATCHES "^[<>].*[<>]$")
          message(FATAL_ERROR "invalid range: ${current_expression}")
        endif()
        map_new()
        ans(next_value)
        map_set("${next_value}" "${current_expression}" "${current_value}")
        set(current_value "${next_value}")
      endif()
    endwhile()
    return_ref(current_value)
  endfunction()







## `(<current value:<any>> ["&"]<navigation expression>)-><any>`
## navigates the specified value and returns the value the navigation expression 
## points to.  If the value does not exist nothing is returned
## 
## if the expression is prepended by an ampersand `&` the current lvalue is returned.
## 
## **Examples**<%
##  set(data_input "{a:{b:{c:3},d:[{e:4},{e:5}]}}")
##  script("${data_input}")
##  ans(data)
##  function(ref_nav_get_example )
##    set(expr ${ARGN})
##    ref_nav_get("${data}" ${expr})
##    ans(res)
##    json("${res}")
##    ans(res)
##    return("`ref_nav_get(\\\${data} ${expr}) => ${res}`")
##  endfunction()
##  set(asdas 123)
## %>
## let `${data}` be `@json(${data_input})`
## then 
## * @ref_nav_get_example(a)
## * @ref_nav_get_example(a.b.c)
## * @ref_nav_get_example(a.b.c.d)
## * @ref_nav_get_example(a.d[1].e) 
## * @ref_nav_get_example(a.d[0].e)
## * @ref_nav_get_example(a.d)
## * @ref_nav_get_example()
## * @ref_nav_get_example(&a.b.c)
function(ref_nav_get current_value)
  set(expression ${ARGN})
  if("${expression}" MATCHES "^&(.*)")
    set(return_lvalue true )
    set(expression "${CMAKE_MATCH_1}")
  else()
    set(return_lvalue false)
  endif()

  navigation_expression_parse("${expression}")
  ans(expression)

  set(current_ref)
  set(current_property)
  set(current_ranges)
  foreach(current_expression ${expression})
    if("${current_expression}" MATCHES "^[<>].*[<>]$")
      list_range_try_get(current_value "${current_expression}")
      ans(current_value)
      list(APPEND current_ranges ${current_expression})
    else()
      is_address("${current_value}")
      #is_map("${current_value}")
      ans(is_ref)
      if(NOT is_ref)
        set(current_value)
        break()
      endif()
      set(current_ref "${current_value}")
      set(current_property "${current_expression}")
      set(current_ranges)

      ref_prop_get("${current_value}" "${current_expression}")
      ans(current_value)
    endif()
  endforeach()
  if(return_lvalue)
    map_capture_new(ref:current_ref property:current_property range:current_ranges value:current_value --reassign)
    return_ans()
  endif()
  return_ref(current_value)

endfunction()





## `(<base_value:<any>> ["!"]<navigation expresion> <value...>)-><any>`
##
## sets the specified navigation expression to the the value
## taking into consideration the base_value.
##
##
##
function(ref_nav_set base_value expression)
  string_take(expression "!")
  ans(create_path)

  navigation_expression_parse("${expression}")
  ans(expression)
  set(expression ${expression})

  set(current_value "${base_value}")
  set(current_ranges)
  set(current_property)
  set(current_ref)
  # this loop  navigates through existing values using ranges and properties as navigation expressions
  # the 4 vars declared before this comment will be defined
  while(true)
    list(LENGTH expression continue)
    if(NOT continue)
      break()
    endif()

    list_pop_front(expression)
    ans(current_expression)

    set(is_property true)
    if("${current_expression}" MATCHES "^[<>].*[<>]$")
      set(is_property false)
    endif()
 #   print_vars(current_expression is_property)
    if(is_property)

      #is_map("${current_value}")
      is_address("${current_value}")
      ans(is_ref)
      if(is_ref)
          set(current_ref "${current_value}")
          set(current_property "${current_expression}")
          set(current_ranges) 
      else()
        list_push_front(expression "${current_expression}")
        break()
      endif()

      ref_prop_get("${current_value}" "${current_expression}")
      ans(current_value)
    else()
      list_range_try_get(current_value "${current_expression}")
      ans(current_value)
      list(APPEND current_ranges "${current_expression}")
    endif()
  endwhile()



  set(value ${ARGN})
  
  # if the expressions are left and create_path is not specified
  # this will cause an error else the rest of the path is created
  list(LENGTH expression expression_count)
  if(expression_count GREATER 0)
    if(NOT create_path)
      message(FATAL_ERROR "could not find path ${expression}")
    endif()
    ref_nav_create_path("${expression}" ${value})
    ans(value)
  endif()

  ## get the last existing value
  if(current_ref)
    ref_prop_get("${current_ref}" "${current_property}")
    ans(current_value)
  else()
    set(current_value ${base_value})
  endif()

  ## if there are ranges set the interpret the value as a lsit and set the correct element
  list(LENGTH current_ranges range_count)
  if(range_count GREATER 0)
    list_range_partial_write(current_value "${current_ranges}" "${value}")
  else()
    set(current_value "${value}")
  endif()

  ## either return a new base balue or set the property of the last existing ref
  if(NOT current_ref)    
    set(base_value "${current_value}")
  else()
    ref_prop_set("${current_ref}" "${current_property}" "${current_value}")
  endif()

  return_ref(base_value)
endfunction()






  function(ref_prop_get ref prop)
    map_get_special("${ref}" object)
    ans(isobject)
    if(isobject)
      obj_get("${ref}" "${prop}")
    else()
      map_tryget("${ref}" "${prop}")
    endif()
    return_ans()
  endfunction()

  ## faster
  macro(ref_prop_get ref prop)
    map_get_special("${ref}" object)
    ans(isobject)
    if(isobject)
      obj_get("${ref}" "${prop}")
    else()
      map_tryget("${ref}" "${prop}")
    endif()
  endmacro()





  function(ref_prop_set ref prop)
    map_get_special("${ref}" object)
    ans(isobject)
    if(isobject)
      obj_set("${ref}" "${prop}" ${ARGN})
    else()
      map_set("${ref}" "${prop}" ${ARGN})
    endif()
  endfunction()






  # calls the object itself
  function(obj_call obj)
    map_get_special("${obj}" "call")
    ans(call)

    if(NOT call)
      message(FATAL_ERROR "cannot call '${obj}' - it has no call function defined")
    endif()
    set(this "${obj}")
    call("${call}" (${ARGN}))
    ans(res)
    return_ref(res )
  endfunction()




function(obj_delete this)
 	map_delete(${this})
endfunction()







# returns the objects value at ${key}
function(obj_get this key)
  map_get_special("${this}" "get_${key}")
  ans(getter)
  if(NOT getter)
    map_get_special("${this}" "getter")
    ans(getter)    
    if(NOT getter)
      obj_default_getter("${this}" "${key}")
      return_ans()
    endif()

  endif()
  set_ans("")
  eval("${getter}(\"\${this}\" \"\${key}\")")
  return_ans()
endfunction()








  function(obj_has obj key)
    map_get_special("${obj}" has)
    ans(has)
    if(NOT has)
      obj_default_has_member("${obj}" "${key}")
      return_ans()
    endif()
    set_ans("")
    eval("${has}(\"\${obj}\" \"\${key}\")")
    return_ans()
  endfunction()






  # returns all keys for the specified object
  function(obj_keys obj)
    map_get_special("${obj}" get_keys)
    ans(get_keys)
    if(NOT get_keys)
      obj_default_get_keys("${obj}")
      return_ans()
    endif()
    set_ans("")
    eval("${get_keys}(\"\${obj}\")")
    return_ans()
  endfunction()




# 
function(obj_member_call this key)
  #message("obj_member_call ${this}.${key}(${ARGN})")
  map_get_special("${this}" "member_call")
  ans(member_call)
  if(NOT member_call)
    obj_default_member_call("${this}" "${key}" ${ARGN})
    return_ans()
    #set(member_call obj_default_callmember)
  endif()
  call("${member_call}" ("${this}" "${key}" ${ARGN}))
  return_ans()
endfunction()






function(obj_new)
	set(args ${ARGN})
	list_pop_front( args)
	ans(constructor)
	list(LENGTH constructor has_constructor)
	if(NOT has_constructor)
		set(constructor Object)
	endif()
	

	if(NOT COMMAND "${constructor}")
	
		message(FATAL_ERROR "obj_new: invalid type defined: ${constructor}, expected a cmake function")
	endif()

	type_get(${constructor})
	ans(base)
	map_get_special(${base} constructor)
	ans(constr)

	map_new()
	ans(instance)

	obj_setprototype(${instance} ${base})


	set(__current_constructor ${constructor})
	obj_member_call(${instance} __constructor__ ${args})
	ans(res)


	if(res)
		set(instance "${res}")
	endif()

	map_set_special(${instance} "object" true)

	return_ref(instance)
endfunction()





  # sets the objects value at ${key}
  function(obj_set this key)

    map_get_special("${this}" "set_${key}")
    ans(setter)
    if(NOT setter)
      map_get_special("${this}" "setter")
      ans(setter)
      if(NOT setter)
        obj_default_setter("${this}" "${key}" "${ARGN}")
        return_ans()
      endif()
    endif()
    set_ans("")
    eval("${setter}(\"\${this}\" \"\${key}\" \"${ARGN}\")")
    return_ans()
  endfunction()




  # default getter for object properties tries to get
  # the maps own value and if not looks for the prototype
  # special field and calls obj_get on it
  function(obj_default_getter obj key)
    map_has("${obj}" "${key}")
    ans(has_own_property)
    if(has_own_property)
      map_tryget("${obj}" "${key}")
      return_ans()  
    endif()

    map_get_special("${obj}" "prototype")
    ans(prototype)
    #message("proto is ${prototype}")
    if(NOT prototype)
      return()
    endif()

    obj_get("${prototype}" "${key}")
    return_ans()
  endfunction()




# default implementation for returning all avaialbe keys
function(obj_default_get_keys obj)
  map_keys("${obj}")
  ans(ownkeys)
  map_get_special("${obj}" "prototype")
  ans(prototype)
  if(NOT prototype)
    return_ref(ownkeys)
  endif()
  obj_keys("${prototype}")
  ans(parent_keys)
  set(keys ${ownkeys} ${parent_keys})
  list(LENGTH keys len)
  if(${len} GREATER 1)
    list(REMOVE_DUPLICATES keys)
  endif()
  return_ref(keys)
endfunction()




function(obj_default_has_member obj key)
  map_has("${obj}" "${key}")
  ans(has_member)
  if(has_member)
    return(true)
  endif()
  obj_getprototype("${obj}")
  ans(proto)
  if(NOT proto)
    return(false)
  endif()
  obj_has("${proto}" "${key}")
  return_ans()
endfunction()





# default implementation for calling a member
# imports all vars int context scope
# and binds this to the calling object
function(obj_default_member_call this key)
  #message("obj_default_callmember ${this}.${key}(${ARGN})")
  obj_get("${this}" "${key}")
  ans(member_function)
  if(NOT member_function)
    message(FATAL_ERROR "member does not exists '${this}.${key}'")
  endif()
  # this elevates all values of obj into the execution scope
  #obj_import("${this}")  
  call("${member_function}"(${ARGN}))
  return_ans()
endfunction()









  # default setter for object properties sets the
  # owned value @ key
  function(obj_default_setter obj key value)
    map_set("${obj}" "${key}" "${value}")
    return()
  endfunction()





function(obj_injectable_callmember this key)
  map_get_special("${this}" before_call)
  ans(before_call)
  map_get_special("${this}" after_call)
  ans(after_call)

  set(call_this ${this})
  set(call_args ${ARGN})
  set(call_key ${key})
  set(call_result)
  
  if(before_call)
    call("${before_call}"())
  endif()
  obj_default_member_call("${this}" "${key}" "${ARGN}")
  ans(call_result)
  if(after_call)
    call("${after_call}"())
  endif()
  return_ref(call_result)
endfunction()


function(obj_before_callmember obj func)
  map_set_special("${obj}" call_member obj_injectable_callmember)
  map_set_special("${obj}" before_call "${func}")
endfunction()

function(obj_after_callmember obj func)
  map_set_special("${obj}" call_member obj_injectable_callmember)
  map_set_special("${obj}" after_call "${func}")
endfunction()






  ## tries to parse structured data
  ## if structured data is not parsable returns the value passed
  function(data)
    set(result)
    set(args ${ARGN})
    foreach(arg ${args})
      if("_${arg}" MATCHES "^_(\\[|{).*(\\]|})$")
        script("${arg}")
        ans(val)
      else()
        set(val "${arg}")        
      endif()
      list(APPEND result "${val}")
    endforeach()  
    return_ref(result)
  endfunction()




# shorthand for map_new and obj_new
# accepts a Type (which has to be a cmake function)
function(new)
  obj_new(${ARGN})
  return_ans()
endfunction()


  




# returns an object from string, or reference
# ie obj("{id:1, test:'asd'}") will return an object
  function(obj object_ish)
    is_map("${object_ish}")
    ans(isobj)
    if(isobj)
      return("${object_ish}")
    endif()
    if("${object_ish}" MATCHES "^{.*}$")
     script("${object_ish}")
     return_ans()
    endif()
    return()
  endfunction()






# converts the <structured data?!...> into  <structured data...>
function(objs)
  set(res)
  foreach(arg ${ARGN})
    obj(${arg})
    ans(arg)
    list(APPEND res "${arg}")
  endforeach()
  return_ref(res)
endfunction()




## capture the specified variables in the specified obj
function(obj_capture map)
   set(__obj_capture_args ${ARGN})
    list_extract_flag(__obj_capture_args --notnull)
    ans(__not_null)
    foreach(__obj_capture_arg ${ARGN})
      if("${__obj_capture_arg}" MATCHES "(.+)[:=](.+)")
        set(__obj_capture_arg_key ${CMAKE_MATCH_1})
        set(__obj_capture_arg ${CMAKE_MATCH_2})
      else()
        set(__obj_capture_arg_key "${__obj_capture_arg}")
      endif()
     # print_vars(__obj_capture_arg __obj_capture_arg_key)
      if(NOT __not_null OR NOT "${${__obj_capture_arg}}_" STREQUAL "_")
        obj_set(${map} "${__obj_capture_arg_key}" "${${__obj_capture_arg}}")
      endif()
    endforeach()

endfunction()






function(obj_declare_call obj out_function_name)
  function_new()
  ans(callfunc)
  map_set_special("${obj}" call "${callfunc}")
  set("${out_function_name}" "${callfunc}" PARENT_SCOPE)  
endfunction()  





  function(obj_declare_getter obj function_name_ref)
      function_new()
      ans(func)
      map_set_special(${obj} getter "${func}")
      set(${function_name_ref} ${func} PARENT_SCOPE)
      return()
  endfunction()





function(obj_declare_get_keys obj function_ref)
    function_new()
    ans(func)
    map_set_special(${obj} get_keys ${func})
    set(${function_ref} ${func} PARENT_SCOPE)
  endfunction()






  function(obj_declare_member_call obj function_ref) 
    function_new()
    ans(func)
    map_set_special(${obj} member_call ${func})
    set(${function_ref} ${func} PARENT_SCOPE)
  endfunction()




## declares a programmou able property 
## if one var arg is specified the function is ussed as a getter
## if there are more the one args you need to label the getter with --getter and setter with --setter
## if no var arg is specified the two functions will be created call
## get_${property_name} and set_${property_name}

  function(obj_declare_property obj property_name)
    set(args ${ARGN})
    list_extract_flag(args --hidden)
    ans(hidden)
    if(hidden)
      set(hidden --hidden)
    else()
      set(hidden)
    endif()

    list(LENGTH args len)
    if(${len} EQUAL 0)
      set(getter "get_${property_name}")
      set(setter "set_${property_name}")
    elseif(${len} GREATER 1)
      list_extract_labelled_value(args --getter)
      ans(getter)
      list_extract_labelled_value(args --setter)
      ans(setter)
    else()
      set(getter ${args})
    endif()

    if(getter)
      obj_declare_property_getter("${obj}" "${property_name}" "${getter}" ${hidden})
      set(${getter} ${${getter}} PARENT_SCOPE)
    endif()
    if(setter)
      obj_declare_property_setter("${obj}" "${property_name}" "${setter}" ${hidden})
      set(${setter} ${${setter}} PARENT_SCOPE)
    endif()
  endfunction()






  ## obj_declare_property_getter(<objref> <propname:string> <getter:cmake function ref>)
  ## declares a property getter for a specific property
  ## after the call getter will contain a function name which needs to be implemented
  ## the getter function signature is (current_object key values...)
  ## the getter function also has access to `this` variable
  function(obj_declare_property_getter obj property_name getter)
    set(args ${ARGN})
    list_extract_flag(args --hidden)
    ans(hidden)
    function_new()
    ans("${getter}")
    if(NOT hidden)
      map_set("${obj}" "${property_name}" "")
    endif()
    map_set_special("${obj}" "get_${property_name}" "${${getter}}")
    set("${getter}" "${${getter}}" PARENT_SCOPE)
  endfunction()




## sets the a setter functions for a specific property
  function(obj_declare_property_setter obj property_name setter)
    set(args ${ARGN})
    list_extract_flag(args --hidden)
    ans(hidden)
    function_new()
    ans("${setter}")
    if(NOT hidden)
      map_set("${obj}" "${property_name}" "")
    endif()
    map_set_special("${obj}" "set_${property_name}" "${${setter}}")
    set("${setter}" "${${setter}}" PARENT_SCOPE)

  endfunction()






  function(obj_declare_setter obj function_ref)
    function_new()
    ans(res)
    map_set_special(${obj} setter ${res})
    set(${function_ref} ${res} PARENT_SCOPE)
  endfunction()





# returns a list of prototypes for ${this}
function(obj_gethierarchy this )
	set(current ${this})
	set(types)
	while(current)
		obj_gettype(${current} )
		ans(type)
		if(type)
			list(APPEND types ${type})
		endif()
		obj_getprototype(${current} )
		ans(proto)
		set(current ${proto})
	endwhile()

	return_ref(types)
endfunction()





  function(obj_getprototype obj)
    map_get_special("${obj}" prototype)
    ans(res)
    return_ref(res)
  endfunction()




function(obj_gettype obj)
	obj_getprototype(${obj} )
  ans(proto)
	if(NOT proto)
    return()
	endif()
  map_get_special(${proto} constructor)
  ans(res)
	return_ref(res)
endfunction()


function(typeof obj)
  obj_gettype("${obj}")
  return_ans()
endfunction()





  function(obj_import obj)
    if(ARGN)
      foreach(arg ${ARGN})
        obj_get("${obj}" "${arg}")
        ans(val)
        set("${arg}" "${val}" PARENT_SCOPE)
      endforeach()
    endif()
    obj_keys("${obj}")
    ans(keys)
    foreach(key ${keys})
      obj_get("${obj}" "${key}")
      ans(val)
      set("${key}" "${val}" PARENT_SCOPE)
    endforeach()

  endfunction()




# returns true iff obj is ${typename}
function(obj_istype this typename)
	obj_gethierarchy(${this} )
  ans(hierarchy)
	list(FIND hierarchy ${typename} index)
	if(${index} LESS 0)
		return(false)
	endif()
		return(true)
	endif()
endfunction()






  # creates a new map only getting the specified keys
  function(obj_pick map)
    map_new()
    ans(res)
    foreach(key ${ARGN})
      obj_get(${map} "${key}")
      ans(val)

      map_set("${res}" "${key}" "${val}")
    endforeach()
    return("${res}")
  endfunction()





  function(obj_setprototype obj prototype)
    map_set_special("${obj}" prototype "${prototype}")
    return()
  endfunction()




function(obj_typecheck this typename)
  obj_istype(${this}  ${typename})
  ans(res)
  if(NOT res)
    obj_gettype(${this} )
    ans(actual)
  	message(FATAL_ERROR "type exception expected '${typename} but got '${actual}'")

  endif()
endfunction()




function(type_exists type)

endfunction()

function(type_get type)
	if(NOT COMMAND ${type})
		message(FATAL_ERROR "obj_new: only cmake functions are allowed as types, '${type}' is not function")
	endif()	
	set(base)
	#get_property(base GLOBAL PROPERTY "type_${type}")
	if(NOT base)
		map_new()
		ans(base)
		
		set_property(GLOBAL PROPERTY "type_${type}" "${base}")
		map_set_special("${base}" constructor "${type}")
	endif()
	return_ref(base)
endfunction()




## shorthand for obj_declare_property 
##
macro(property)
  obj_declare_property(${this} ${ARGN})
endmacro()





function(proto_declarefunction result)
  string(REGEX MATCH "[a-zA-Z0-9_]+" match "${result}")
  set(function_name "${match}")
  obj_getprototype(${this})
  ans(proto)
	if(NOT proto)
		message(FATAL_ERROR "proto_declarefunction: expected prototype to be present")
	endif()
	set(res ${result})
  set(__current_member ${function_name})
  function_new(${function_name} ${ARGN})
  ans(func)
  obj_set("${proto}" "${function_name}" "${func}")
	#obj_declarefunction(${proto} ${res})
	set(${function_name} "${func}" PARENT_SCOPE)
endfunction()


## shorthand for proto_declarefunction
macro(method result)
  proto_declarefunction("${result}")
endmacro()


# causes the following code inside a constructor to only run once
macro(begin_methods)

endmacro()




# appends the value(s) to the specified member variable
function(this_append member_name)
  obj_get("${this}" "${member_name}")
  ans(value)
  obj_set("${this}" "${member_name}" ${value} "${ARGN}")
endfunction()





function(this_callmember function)
	obj_member_call("${this}" "${function}" ${ARGN})
  return_ans()
endfunction()





  macro(this_capture)
    obj_capture(${this} ${ARGN})
  endmacro()







function(this_declarefunction result)
	this_check()
	obj_declarefunction(${this} ${result})
	return_value(${${result}})
endfunction()




function(this_declare_call out_function_name)
  function_new()
  ans(callfunc)
  map_set_special("${this}" call "${callfunc}")
  set(${out_function_name} ${callfunc} PARENT_SCOPE)
endfunction()






  function(this_declare_getter function_name_ref)
    obj_declare_getter(${this} _res)
    set(${function_name_ref} ${_res} PARENT_SCOPE)
    return()
  endfunction()





  function(this_declare_get_keys function_ref)
    obj_declare_get_keys(${this} _ref)
    set(${function_ref} ${_ref} PARENT_SCOPE)
  endfunction()





  function(this_declare_member_call function_ref)
    obj_declare_member_call(${this} _res)
    set(${function_ref} ${_res} PARENT_SCOPE)
  endfunction()







  function(this_declare_setter function_ref)
    obj_declare_setter(${this} _ref)
    set(${function_ref} ${_ref} PARENT_SCOPE)
  endfunction()






macro(this_get member_name)
	obj_get("${this}" "${member_name}")
  ans("${member_name}")
endmacro()




# imports all variables specified as varargs
macro(this_import)
  obj_import("${this}" ${ARGN})
endmacro()




#inherits from base (if base is an objct it will be set as the prototype of this)
# if base is a function / constructor then a base object will be constructed and set
# as the prototy of this
function(this_inherit baseType)
	type_get( ${baseType})
	ans(base)
	obj_getprototype(${this})
	ans(prototype)
	obj_setprototype(${prototype} ${base})
	map_get_special(${base} constructor)
	ans(super)
	function_import("${super}" as base_constructor REDEFINE)
	clr()	
  set(__current_constructor "${super}")
  obj_setprototype(${this} ${base})
	base_constructor(${ARGN})
	obj_setprototype(${this} ${prototype})
	ans(instance)
	if(instance)
		set(this "${instance}" PARENT_SCOPE)
	endif()
endfunction()


## todo
function(obj_inherit)

endfunction()




# sets both the objects proerpty and the local cmake variable called ${member_name}
function(this_set member_name)
	obj_set("${this}" "${member_name}" "${ARGN}")
	set(${member_name} "${ARGN}" PARENT_SCOPE)
endfunction()






function(this_setprototype proto_ref)
	obj_setprototype(${this} ${proto_ref})
endfunction()





## `(<package handle> <content_dir: <path>>)-><bool>`
## checks to see if the package content is valid at the specified locatin
## returns true if so else returns false
function(package_content_check package_handle content_dir)
  path_qualify(content_dir)
  if(NOT EXISTS "${content_dir}")
    return(false)
  endif()
  return(true)
endfunction()




## `(<dependency changeset>|<change ...>)-><dependency changeset>`
##
## returns a `<dependency changeset>`
## ```
## <dependency changeset>::={
##  <<admissable uri>:<dependency constraint>>... 
## }
## <change> ::= <admissable uri> [" " <dependency constraint> | "remove"  ] 
## ``` 
##
function(package_dependency_changeset)
  is_address("${ARGN}")
  ans(isref)
  if(isref)
    return(${ARGN})
  endif()
  package_dependency_changeset_parse(${ARGN})
  return_ans()
endfunction()





## `()->`
##
##
function(package_dependency_changeset_parse)
  map_new()
  ans(changeset)
  foreach(action ${ARGN})
    package_dependency_change_parse("${action}")
    ans_extract(admissable_uri)
    ans(action)
    if(NOT "${admissable_uri}_" STREQUAL "_")
      map_set("${changeset}" "${admissable_uri}" "${action}")
    endif()
  endforeach()
  return_ref(changeset)
endfunction()




## `(<change action>)->[ <admissable uri>, <action>]`
##
## parses a change action `<change action> ::= <admissable uri> [" " <action>]`
## `<action> ::= "add"|"remove"|"optional"|<dependency constraint>`
## the default action is `add`
function(package_dependency_change_parse)
  set(action ${ARGN})
  string_take_regex(action "[^ ]+")
  ans(admissable_uri)
  if("${admissable_uri}_" STREQUAL "_")
    return()
  endif()
  string_take_whitespace(action)
  data("${action}")
  ans(action)

  if("${action}_" STREQUAL "_")
    set(action add)
  endif()

  is_address(${action})
  ans(isref)  
  if(isref)
    set(action add ${action})
  elseif("${action}" MATCHES "^((add)|(remove)|(optional)|(conflict))$")
    set(action ${CMAKE_MATCH_1})
  else()
    message(FATAL_ERROR "invalid change: ${action}")
  endif()

  set(result ${admissable_uri} ${action})
  return_ref(result)
endfunction()




## `(<package source> <package handle>  [--cache <map>] )-> <dependency configuration>`
##  
## the `<dependency configuration> ::= { <<dependable uri>:<bool>>... }`
## is a map which indicates which dependencies MUST BE present and which MAY NOT
##
##  returns a map of `package uri`s which consist of a valid dependency configuration
##  { <package uri>:{ state: required|incompatible|optional}, package_handle{ dependencies: {packageuri: package handle} } }
##  or a reason why the configuration is impossible
##
##  **sideffects**
## *sets the `dependencies` property of all `package handle`s to the configured dependency using `package_dependency_configuration_set`.
##  
function(package_dependency_configuration package_source root_handle)  
  package_dependency_resolve_and_satisfy("${package_source}" "${root_handle}" ${ARGN})
  ans(dependency_problem)

  ## get the assignments
  map_tryget(${dependency_problem} dp_result)
  ans(dp_result)
  map_tryget(${dp_result} atom_assignments)
  ans(assignments)

  return_ref(assignments)
endfunction()








## `(<lhs: <dependency configuration>> <rhs:<dependency configuration>>-><changeset>`
## 
## compares two dependency configurations and returns a resulting changeset
## the `<changeset> ::= { <dependable uri>:"install"|"uninstall"}` 
function(package_dependency_configuration_changeset lhs rhs)
    set(package_uris)
    map_keys(${lhs})
    ans_append(package_uris)
    map_keys(${rhs})
    ans_append(package_uris)
    list_remove_duplicates(package_uris)

    map_new()
    ans(changeset)


    foreach(package_uri ${package_uris})
      map_tryget(${lhs} ${package_uri})
      ans(before)
      map_tryget(${rhs} ${package_uri})
      ans(after)

      set(action)

      if(NOT after)
        if(NOT "${before}_" STREQUAL "false_")
          set(action uninstall)
        endif()
      elseif(after AND NOT before)
        set(action install)

      endif()

      if(action)
        map_set(${changeset} ${package_uri} ${action})
      endif()
    endforeach()

    return_ref(changeset)
endfunction()  




##
##
## takes a specific dependency configuration and a set of package descriptors from
## a package graph obtained by package_dependency_graph_resolve and updates 
## the package_handle's dependencies property to contain a single unique package handle 
## for every admissable_uri. before the dependencies property maps admissable_uri x {package uri x package handle}
##
function(package_dependency_configuration_set configuration)
  set(package_handles ${ARGN})

  foreach(package_handle ${package_handles})
    map_tryget(${package_handle} dependencies)
    ans(dependencies)
    if(dependencies)
      map_keys(${dependencies})
      ans(admissable_uris)

      foreach(admissable_uri ${admissable_uris})
        map_tryget(${dependencies} ${admissable_uri})
        ans(possible_dependencies)
        map_values(${possible_dependencies})
        ans(possible_dependencies)
        map_set(${dependencies} ${admissable_uri})

        foreach(possible_dependency ${possible_dependencies})
          map_tryget(${possible_dependency} uri)
          ans(possible_dependency_uri)

          map_has(${configuration} ${possible_dependency_uri})
          ans(has_uri)
          if(has_uri)
            map_set(${dependencies} ${admissable_uri} ${possible_dependency})
            break()
          endif()
        endforeach()
      endforeach()

    endif()
  endforeach()
endfunction()




## `()-><dependency configuration>`
##
## 
function(package_dependency_configuration_update package_source project_handle)
  set(args ${ARGN})
  ## get cache if available - else create a new one
  list_extract_labelled_value(args --cache)
  ans(cache)
  if(NOT cache)
    map_new()
    ans(cache)
  endif()

  package_handle_update_dependencies(${project_handle} ${args})
  ans(changes)

  package_dependency_configuration("${package_source}" "${project_handle}" --cache ${cache})
  ans(configuration)

  return_ref(configuration)
endfunction()








## `(<dependency_graph:{ <package uri>:<package handle>... }> <root handle:<package handle>>) -> { <<clause index>: <clause>>...}`
## 
## creates cnf clauses for all dependencies in dependency graph
## 
##
function(package_dependency_clauses dependency_problem) 
  map_tryget(${dependency_problem} package_graph)
  ans(package_graph)


  map_values("${package_graph}")
  ans(package_handles)

  set(derived_constraints)
  ## loop through all package handles in dependency graph 
  ## and add their dependency clauses to clauses sequence
  foreach(package_handle ${package_handles})      
    package_dependency_constraint_derive_all("${dependency_problem}" "${package_handle}")
    ans_append(derived_constraints)
  endforeach()

  set(clauses)
  foreach(constraint ${derived_constraints})
    map_tryget(${constraint} clauses)
    ans_append(clauses)
  endforeach()

  

  return_ref(clauses)
endfunction()






function(package_dependency_constraint type package_handle)
  map_new()
  ans(constraint)
  map_set(${constraint} type "${type}")
  map_set(${constraint} package_handle "${package_handle}")
  return(${constraint})
endfunction()






function(package_dependency_constraint_clause constraint reason)
  format("${reason}")
  ans(reason)
  set(literals ${ARGN})
  map_new()
  ans(clause)

  map_set(${clause} reason "${reason}")
  foreach(literal ${literals})
    if("${literal}" MATCHES "^!(.+)")
      map_tryget(${CMAKE_MATCH_1} uri)
      ans(uri)
      map_append(${clause} literals "!${uri}")
    else()
      map_tryget(${literal} uri)
      ans(uri)
      map_append(${clause} literals "${uri}")
    endif()
  endforeach()

  map_set(${clause} constraint ${constraint})
  map_append(${constraint} clauses ${clause})

  return(${clause})
endfunction()




## this function adds to the `clauses` of the `dependency_problem`
## it uses the constraint handlers specified in the problems 
## `constraint_handlers` property.  the constraint handlers derive clauses 
## dependeing on the dependency_constraint
function(package_dependency_constraint_derive
  dependency_problem
  dependee_handle 
  admissable_uri
  dependency_constraint
  possible_dependencies
  )

  ## if dependency_constraint is a map it is a valid depndency constraint
  is_address("${dependency_constraint}")
  ans(is_address)
  if(is_address)

    map_tryget(${dependency_constraint} constraint_type)
    ans(constraint_type)

    if("${constraint_type}_" STREQUAL "_")
        map_set(${dependency_constraint} constraint_type "required")
        set(constraint_type "required")
    endif()

    if("${constraint_type}_" STREQUAL "_")
        error("invalid constraint type for {dependee_handle.uri} => {admissable_uri} (got '{constraint_type}')")
      return()
    endif()

    set(derived_constraints)
    map_tryget(${dependency_problem} constraint_handlers)
    ans(constraint_handlers)
    foreach(handler ${constraint_handlers})
      call2(
        "${handler}" 
        "${dependency_problem}" 
        "${dependee_handle}" 
        "${admissable_uri}" 
        "${dependency_constraint}"
        "${possible_dependencies}"
        )
      ans_append(derived_constraints)
    endforeach()

    return_ref(derived_constraints)
  endif()

  ## if the dependency_constraint is not a map it may either by empty, optional , true or false
  ## the correct object will be created and recursively handled
  if("${dependency_constraint}_" STREQUAL "_" OR "${dependency_constraint}_" STREQUAL "optional_")
    map_new()
    ans(dependency_constraint)
    map_set(${dependency_constraint} constraint_type optional)
  elseif("${dependency_constraint}" MATCHES "^((true)|(false))$")
    map_new()
    ans(dependency_constraint)

    if(CMAKE_MATCH_1)
      map_set(${dependency_constraint} constraint_type required)
    else()
      map_set(${dependency_constraint} constraint_type incompatible)
    endif()
  else()
    error("invalid dependency constraint: '${dependency_constraint}'")
    return()
  endif()

  package_dependency_constraint_derive(
    "${dependency_problem}"
    "${dependee_handle}"
    "${admissable_uri}"
    "${dependency_constraint}"
    "${possible_dependencies}"
    )
  return_ans()
endfunction()




## `(<clauses:<sequence>> <dependee_handle:<package handle>>)-><void>`
##
##
## adds depdency clauses resulting from dependee handle to the 
## clauses sequence.  Currently only supports  
##
## **currently only supports true, false and "" constraints**
function(package_dependency_constraint_derive_all dependency_problem dependee_handle)

  map_tryget(${dependee_handle} dependencies)
  ans(dependencies)

  map_tryget(${dependee_handle} package_descriptor)
  ans(package_descriptor)

  map_tryget("${package_descriptor}" dependencies)
  ans(constraints)

  map_keys(${dependencies})
  ans(admissable_uris)

  ## todo:  this has to become nicer.....
  map_new()
  ans(empty)
  map_new()
  ans(package_constraint)
  map_set(${package_constraint} constraint_type "package_constraint")
  ## derive package constraints
  package_dependency_constraint_derive(
    "${dependency_problem}"
    "${dependee_handle}"
    "self"
    "${package_constraint}" 
    "${empty}")
  ans(derived_constraints)

  

  foreach(admissable_uri ${admissable_uris})
    map_tryget("${constraints}" "${admissable_uri}")
    ans(dependency_constraint)

    ## gets all dependency handles for admissable_uri
    map_tryget("${dependencies}" "${admissable_uri}")
    ans(dependency_handle_map)
    
    package_dependency_constraint_derive(
      "${dependency_problem}"
      "${dependee_handle}" 
      "${admissable_uri}"
      "${dependency_constraint}" 
      "${dependency_handle_map}"
    )
    ans_append(derived_constraints)

  endforeach()

  return_ref(derived_constraints)
endfunction()





function(package_dependency_constraint_incompatible
  dependency_problem 
  dependee
  admissable_uri 
  dependency_constraint
  possible_dependencies
  )
  
  ## ignore constraints which are not "incompatible" type
  map_tryget(${dependency_constraint} constraint_type)
  ans(constraint_type)

  if(NOT "${constraint_type}" STREQUAL "incompatible")
    return()
  endif()


  package_dependency_constraint("incompatible" "${dependee}")
  ans(constraint)

  map_values(${possible_dependencies})
  ans(dependencies)
  foreach(dependency ${dependencies})
    package_dependency_constraint_clause(
      ${constraint}
      "'{dependee.uri}' is incompatible with '{dependency.uri}'" 
      "!${dependee}" "!${dependency}")
  endforeach()

  return(${constraint})
endfunction()





function(package_dependency_constraint_mutually_exclusive
   dependency_problem 
  dependee_handle
  admissable_uri 
  dependency_constraint
  possible_dependencies
  )
  ## if dependency is not mutually_exclusive ignore
  map_tryget(${dependency_constraint} mutually_exclusive)
  ans(is_mutually_exclusive)
  if(NOT is_mutually_exclusive)
    return()
  endif()


  package_dependency_constraint("mutually_exclusive" "${dependee_handle}")
  ans(constraint)
  
  ## loop through all dependencies and add the mutual exclusitivity as a clause to the the cosntraint
  map_values(${possible_dependencies})
  ans(dependencies)
  set(current_dependencies ${dependencies})
  foreach(lhs ${dependencies})
    list(REMOVE_ITEM current_dependencies ${lhs})
    foreach(rhs ${current_dependencies})
      package_dependency_constraint_clause(
        ${constraint}
        "mutually exclusivivity" 
        "!${lhs}" "!${rhs}")
    endforeach()
  endforeach()

  return(${constraint})
endfunction()






function(package_dependency_constraint_optional
   dependency_problem 
  dependee_handle
  admissable_uri 
  dependency_constraint
  possible_dependencies)

  ## if constraint type is not optional ignore
  map_tryget(${dependency_constraint} constraint_type)
  ans(constraint_type)
  if(NOT "${constraint_type}_" STREQUAL "optional_")
    return()
  endif()


  package_dependency_constraint("optional" "${dependee_handle}")
  ans(constraint)

  return(${constraint})
endfunction()




## creates the dependency required cosntraint for the specified dependee
function(package_dependency_constraint_required
  dependency_problem 
  dependee
  admissable_uri 
  dependency_constraint
  possible_dependencies
  )
  
  ## if constraint_type is not required ignore
  map_tryget(${dependency_constraint} constraint_type)
  ans(type)
  if(NOT "${type}" STREQUAL "required")
    return()
  endif()

  map_values(${possible_dependencies})
  ans(dependencies)

  package_dependency_constraint("required" "${dependee}")
  ans(constraint)

  ## either depndee is not installed 
  set(clause "!${dependee}")
  foreach(dependency ${dependencies})
    ## or one of the dependencies is installed
    list(APPEND clause "${dependency}")
  endforeach()


  package_dependency_constraint_clause(
    ${constraint}
    "{dependee.uri} => {admissable_uri} requires one of {possible_dependencies.__keys__}" 
    ${clause})


  return(${constraint})
endfunction()





function(package_dependency_constraint_root_package
  dependency_problem 
  dependee_handle
  admissable_uri 
  dependency_constraint
  possible_dependencies)

  map_tryget(${dependency_constraint} constraint_type)
  ans(constraint_type)
  if(NOT "${constraint_type}" STREQUAL "package_constraint")
    return()
  endif()
  ## if root was not yet added and depndee is root package return a required constraint
  map_tryget(${dependency_problem} __root_handle_added)
  ans(__root_handle_added)

  if(__root_handle_added)
    return()
  endif() 



  map_tryget(${dependency_problem} root_handle)
  ans(root_handle)


  if(NOT "${dependee_handle}" STREQUAL "${root_handle}")
    return()
  endif()



  package_dependency_constraint("root_package" "${dependee_handle}")
  ans(constraint)

  package_dependency_constraint_clause(
    ${constraint}
    "root package is always required" 
    "${dependee_handle}")

  return(${constraint})
endfunction()




## constrains the semantic version of a dependency
function(package_dependency_constraint_semantic_version
  dependency_problem 
  dependee
  admissable_uri 
  dependency_constraint
  possible_dependencies)

  ## if dependency constraint does not have a version property then ignore
  map_has(${dependency_constraint} version)
  ans(has_version_constraint)
  if(NOT has_version_constraint)
    return()
  endif()

  ## get version constraint and compile it
  map_tryget(${dependency_constraint} version)
  ans(version_constraint)

  semver_constraint_compile("${version_constraint}")
  ans(compiled_version_constraint)


  ## create the package constraint to return 
  package_dependency_constraint("semantic_version" "${dependee}")
  ans(constraint)


  ## loop through all possible dependencies and if the version constraint does not hold 
  ## add a incompatibility clause to the cosntraint
  map_values(${possible_dependencies})  
  ans(dependencies)
  foreach(dependency ${dependencies})

    ## check version agains the version constraint
    map_tryget(${dependency} package_descriptor)
    ans(package_descriptor)
    map_tryget(${package_descriptor} version)
    ans(version)
    semver_constraint_compiled_evaluate("${compiled_version_constraint}" "${version}")
    ans(holds)

    ## if incompatible add incompatibility
    if(NOT holds)
      package_dependency_constraint_clause(
        ${constraint}
        "{dependee.uri} => {admissable_uri}: is incompatible with {dependency.uri} because version constraint '${version_constraint}' does not hold for '${version}'"
        "!${dependee}"
        "!${dependency}"
        )
    endif()

  endforeach()

  ## success returns a valid package_dependency_constraint
  return(${constraint})

endfunction()




## `(<package source> <package_handles:<package handle>...>  [--cache:<map>])->{ <<package uri>:<package handle>>...}`
##
## resolves the dependecy graphs given by `package_handles`
## returns a map of `<package uri> => <package handle>`
## uses the cache for to lookup `package uri`s
## the `package handle`s all habe a `dependees` and `dependencies` property
## see also `dependencies_resolve`
function(package_dependency_graph_resolve package_source)

  function(expand_dependencies package_source cache context package_handle)
    if(NOT package_handle)
      return()
    endif()
    map_tryget("${package_handle}" uri)
    ans(package_uri)

    #message(FORMAT "package_dependency_graph_resolve: expanding dependencies for ${package_uri}")
    map_has("${context}" "${package_uri}")
    ans(visited)
    if(visited)
      return()
    endif()

    map_set("${context}" "${package_uri}" ${package_handle})
    
    package_dependency_resolve("${package_source}"  "${package_handle}" --cache "${cache}")
    ## flatten the map twice -> results in package handles
    map_flatten(${__ans})
    map_flatten(${__ans})


    return_ans()
  endfunction()

  set(package_handles ${ARGN})
  list_extract_labelled_value(package_handles --cache)
  ans(cache)
  if(NOT cache)
    map_new()
    ans(cache)
  endif()

  ## add the root nodes of the graph into the cache
  foreach(package_handle ${package_handles})
    map_tryget(${package_handle} uri)
    ans(package_uri)
    map_set("${cache}" "${package_uri}" "${package_handle}")
  endforeach()


  ## create context
  map_new()
  ans(context)


  ## get a map of all dependencies mentioned in dependency graph
  curry3(() => expand_dependencies("${package_source}" "${cache}" "${context}" "/*"))
  ans(expand)
  dfs(${expand} ${package_handles})
  return_ref(context)
endfunction()







## `(<package_graph:{ <<package uri>:<package handle>>... }> <requirements:{<<package uri>:<bool>>...>}> )-:{<<package uri>:<bool>>...}`
## 
## not the input package handles need to be part of a package graph
## takes a map of `<package uri>:<package handle>` and returns a map 
## of `<package uri>:<bool>` indicating which package needs to be installd
## any package uri not mentioned in returned map is optional and can be added as a 
## requirement (the the graph has to be resatisfied)
function(package_dependency_graph_satisfy dependency_problem)
  is_address(${dependency_problem})
  ans(is_ok)
  if(NOT is_ok)
    return()
  endif() 

  package_dependency_problem_init("${dependency_problem}")
  ans(success)
  if(NOT success)
    return()
  endif()


  map_tryget(${dependency_problem} cnf)
  ans(cnf)

  ## solve boolean satisfiablitiy problem
  dp_naive("${cnf}")
  ans(result)
  
  package_dependency_problem_run("${dependency_problem}")
  ans(success)
  if(NOT success)
    return()
  endif()



  ## do calculations to complete the problem
  package_dependency_problem_complete("${dependency_problem}")
  ans(result)

  return(${result})
endfunction()






  function(pkg_inst)
    pkg_load()
    ans(project_handle)
    
    default_package_source()
    ans(package_source)
    
    map_tryget(${project_handle} dependency_configuration)
    ans(configuration)

    if(NOT configuration)
      return()
    endif()

    map_keys(${configuration})
    ans(package_uris)

    map_tryget(${project_handle} uri)
    ans(uri)
    list_remove(package_uris ${uri})
    foreach(package_uri ${package_uris})
      string_normalize("${package_uri}")
      ans(target)
      path_qualify(target)
      map_tryget(${configuration} ${package_uri})
      ans(pull)
      if(pull)
        if(NOT EXISTS "${target}")
          message("installing ${package_uri} to ${target}")
          #mkdir("${target}")
          call(package_source.pull(${package_uri} ${target}))
        endif()
      else()
        if(EXISTS "${target}")
          message("deleting ${package_uri} from ${target}")
          
          rm(-r "${target}")
        endif()
      endif()
    endforeach()  

    return(${configuration})

  endfunction()

function(pkg_load)
  path("project.cmake")
  ans(config)
  if(NOT EXISTS "${config}")
    map_new()
    ans(project_handle)
  else()
    cmake_read("${config}")
    ans(project_handle)
  endif()
  map_tryget(${project_handle} uri)
  ans(uri)
  if(NOT uri)
    map_set(${project_handle} uri project:root)

  endif()

  return_ref(project_handle)

endfunction()
function(pkg_save)
  cmake_write("project.cmake" ${project_handle})

endfunction()

function(pkg_dep)
  set(args ${ARGN})
  default_package_source()
  ans(package_source)
  pkg_load()
  ans(project_handle)
 
  project_update_dependencies(${package_source} ${project_handle} ${args})
  ans(res)
 
  pkg_save(${project_handle})
  return_ref(res)
endfunction()


  function(project_update_dependencies package_source project_handle)

    map_tryget(${project_handle} cache)
    ans(cache)
    if(NOT cache)
      map_new()
      ans(cache)
      map_set(${project_handle} cache ${cache})
    endif()


    map_tryget(${project_handle} dependency_configuration)
    ans(previous_configuration)
    if(NOT previous_configuration)
      map_new()
      ans(previous_configuration)
    endif()

    package_dependency_configuration_update(
      ${package_source} 
      ${project_handle} 
      ${ARGN} 
      --cache ${cache}
    )
    ans(configuration)
    map_set(${project_handle} dependency_configuration ${configuration})

    package_dependency_configuration_changeset(${previous_configuration} ${configuration})
    ans(res)


    return_ref(res)
  endfunction()





## ``
##
## creates a package dependency problem context
function(package_dependency_problem package_graph root_handle)
  set(args ${ARGN})

  set(constraint_handlers 
    package_dependency_constraint_required
    package_dependency_constraint_optional
    package_dependency_constraint_mutually_exclusive
    package_dependency_constraint_semantic_version
    package_dependency_constraint_incompatible
    package_dependency_constraint_root_package
    )
  map_capture_new(
    package_graph
    root_handle 
    clauses 
    reasons
    cache
    constraint_handlers
    )
  return_ans()

endfunction()





function(package_dependency_problem_add_constraint_clause problem positive negative reason)
  map_tryget(${dependency_problem} clauses)
  ans(clauses)
  map_tryget(${dependency_problem} reasons)
  ans(reasons)

  set(clause)

  foreach(package_handle ${negative})
    map_tryget(${package_handle} uri)
    ans(uri)
    list(APPEND clause "!${uri}")
  endforeach()
  foreach(package_handle ${positive})
    map_tryget(${package_handle} uri)
    ans(uri)
    list(APPEND clause "${uri}")
  endforeach()
  sequence_add("${clauses}" "${clause}")
  ans(ci)
  map_set(${reasons} "${ci}" "${reason}")
endfunction()






## takes the resolve
function(package_dependency_problem_complete dependency_problem)

  map_tryget(${dependency_problem} dp_result)
  ans(result)


  map_tryget(${result} success)
  ans(success)
  

  if(success)
    map_tryget(${result} assignments)
    ans(assignments)  
    map_tryget(${dependency_problem} cnf)
    ans(cnf)
    literal_to_atom_assignments("${cnf}" "${assignments}")
    ans(atom_assignments)
    map_set(${result} atom_assignments ${atom_assignments})
  endif()

  return(${result})
endfunction()






## initializes the dependency problem after it was configured
function(package_dependency_problem_init dependency_problem)
  is_address("${dependency_problem}")
  ans(is_ok)
  if(NOT is_ok)
    message(FATAL_ERROR "expected a dependency problem object")
  endif()

  ## create boolean satisfiablitiy problem 
  ## by getting all clauses
  package_dependency_clauses(${dependency_problem})
  ans(clauses)
  map_set(${dependency_problem} clauses "${clauses}")  

  ## reformulate clause objects to cnf clauses
  sequence_new()
  ans(cnf_clauses)
  foreach(clause ${clauses})
    map_tryget(${clause} literals)
    ans(literals)
    sequence_add(${cnf_clauses} ${literals})
    ## debug output
    string(REPLACE ";" "|" literals "${literals}")
    message(FORMAT "{clause.reason}.  derived clause: ({literals})")
  endforeach()

  ## create cnf
  cnf("${cnf_clauses}")
  ans(cnf)

  map_set(${dependency_problem} cnf "${cnf}")

  return(true)

endfunction()





function(package_dependency_problem_run package_graph root_handle)

  package_dependency_problem("${package_graph}" "${root_handle}")
  ans(dependency_problem)


  package_dependency_problem_init("${dependency_problem}")  
  ans(success)
  if(NOT success)
    message(FATAL_ERROR "failed to initialize dependency_problem")
  endif()

  package_dependency_problem_solve("${dependency_problem}")
  ans(success)
  if(NOT success)
    message(FATAL_ERROR "failed to solve dependency_problem")
  endif()

  package_dependency_problem_complete("${dependency_problem}")
  ans(success)
  if(NOT success)
    message(FATAL_ERROR "failed to complete dependency_problem")
  endif()

  return_ref(dependency_problem)

endfunction()





# function(package_dependency_problem_solve dependency_problem) 
#   set(args ${ARGN})

#   is_address("${dependency_problem}")
#   ans(ok)
#   if(NOT ok)
#     return()
#   endif()

#   map_import_properties(${dependency_problem} cache root_handle package_source)

#   ## get cache if available - else create a new one
#   if(NOT cache)
#     ## cache map 
#     map_new()
#     ans(cache)
#     map_set(${dependency_problem} cache)
#   endif()


#   ## returns a map of package_uri -> package_handle
#   package_dependency_graph_resolve("${package_source}" ${root_handle} --cache ${cache}) 
#   ans(package_graph)

#   map_set(${dependency_problem} package_graph ${package_graph})

#   ## creates a package configuration which can be rused to install / uninstall 
#   ## dependencies
#   package_dependency_graph_satisfy(${dependency_problem})
#   ans_extract(result)

#   map_tryget(${result} success)
#   ans(success)
#   if(success)
#     map_tryget(${result} atom_assignments)
#     ans(configuration)  
#     map_values(${package_graph})
#     ans(package_handles)
#     package_dependency_configuration_set(${configuration} ${package_handles})
#   else()
#     set(configuration)
#   endif()

#   return(${result})

# endfunction()



function(package_dependency_problem_solve dependency_problem)


  map_tryget(${dependency_problem} cnf)
  ans(cnf)

  ## solve boolean satisfiablitiy problem
  dp_naive("${cnf}")
  ans(result)

  map_set(${dependency_problem} dp_result "${result}")

  return(true)
endfunction()





  function(package_dependency_problem_test project_dependencies constraint_handlers)
      mock_package_source("mock" ${ARGN})
      ans(package_source)

      map_new()
      ans(cache)

      project_open(".")
      ans(project)

      assign(project.project_descriptor.package_source = package_source)


      assign("!project.package_descriptor.dependencies" = "${project_dependencies}")

      package_dependency_graph_resolve("${package_source}" "${project}" --cache ${cache})
      ans(package_graph)

      package_dependency_problem("${package_graph}" "${project}")
      ans(problem)


      assign(problem.constraint_handlers = constraint_handlers)
      
      timer_start(package_dependency_problem_init)
      package_dependency_problem_init("${problem}")
      ans(success)
      timer_print_elapsed(package_dependency_problem_init)

      timer_start(package_dependency_problem_solve)
      package_dependency_problem_solve("${problem}")
      ans(success)
      timer_print_elapsed(package_dependency_problem_solve)

      assign(res = problem.dp_result.initial_context.f.clause_map)

      sequence_to_list("${res}" "|" ")&(")
      ans(res)
      
      set(res "(${res})")
      message("cnf: ${res}")
      return_ref(res)


  endfunction()






## `(<package handle> [--cache <map>])->`
##
##
## resolves all dependencies for the specified package_handle
## keys of `package_handle.package_descriptor.dependencies` are `admissable uri`s 
## `admissable uri`s are resolved to `dependency handle`s 
## returns a map of `<admissable_uri>: <dependency handle>` if no dependencies are present 
## an empty map is returned
## sideffects 
## sets `<package handle>.dependencies.<admissable uri> = { <<dependable uri>:<dependency handle>>... }` 
## adds  to `<dependency handle>.dependees.<package uri> = { <admissable_uri>:<package handle> }` 
function(package_dependency_resolve package_source  package_handle )
  set(args ${ARGN})
  list_extract_labelled_value(args --cache)
  ans(cache)
  if(NOT cache)
    map_new()
    ans(cache)
  endif()

  if(NOT package_handle)
    message(FATAL_ERROR "no package handle specified")
  endif()


  ## get the dependencies specified in package_handle's package_descriptor
  ## it does not matter if the package_descriptor does not exist
  set(admissable_uris)
  map_tryget("${package_handle}" package_descriptor)
  ans(package_descriptor)
  if(package_descriptor)
    map_tryget("${package_descriptor}" dependencies)
    ans(dependencies)
    if(dependencies)
      map_keys("${dependencies}")
      ans(admissable_uris)
    endif()
  endif()

  ## get package uri
  map_tryget(${package_handle} uri)
  ans(package_uri)

  #message(FORMAT "package_dependency_resolve: trying to resolve ${admissable_uris}")

  ## resolve all package dependencies
  ## and assign package handles dependencies property
  package_source_query_resolve_all("${package_source}" ${admissable_uris} --cache ${cache})
  ans(dependencies)

  map_set(${package_handle} dependencies ${dependencies})

  ## loop through all admissable uris 
  ## and assign dependees property 
  
  foreach(admissable_uri ${admissable_uris})
    ## get map for admissable_uri
    map_tryget(${dependencies} "${admissable_uri}")
    ans(dependency)

    map_keys(${dependency})
    ans(dependable_uris)
    foreach(dependency_uri ${dependable_uris})      
      map_tryget(${dependency} ${dependency_uri})
      ans(dependency_handle)
      
      map_tryget(${dependency_handle} dependees)
      ans(dependees)
      if(NOT dependees)
        map_new()
        ans(dependees)
        map_set(${dependency_handle} dependees ${dependees}) 
      endif()
      map_tryget(${dependees} ${package_uri})
      ans(dependee)
      if(NOT dependee)
        map_new()
        ans(dependee)
        map_set(${dependees} ${package_uri} ${dependee})
      endif()
      map_append_unique("${dependee}" "${admissable_uri}" "${package_handle}")
    endforeach()
  endforeach()

  return_ref(dependencies)
endfunction()






function(package_dependency_resolve_and_satisfy package_source root_handle)
  set(args ${ARGN})
  list_extract_labelled_value(args --cache)
  ans(cache)
  ## get cache if available - else create a new one
  if(NOT cache)
    ## cache map 
    map_new()
    ans(cache)
  endif()

  ## resolve graph
  package_dependency_graph_resolve("${package_source}" "${root_handle}" --cache ${cache} )
  ans(package_graph)

  ## run dependency problem
  package_dependency_problem_run("${package_graph}" "${root_handle}")
  ans(dependency_problem)
  
  return_ref(dependency_problem)
endfunction()




## `(<package handle> <~package changeset>)-> <old changes>`
## 
## modified the dependencies of a package handle
## ```
##  package_handle_update_dependencies(${package_handle} "A" "B conflict") 
##  package handle: <%
##    map_new()
##   ans(package_handle)
##   package_handle_update_dependencies(${package_handle} "A" "B conflict")
##   template_out_json(${package_handle})
##  %>
## ```
function(package_handle_update_dependencies package_handle)
  if(NOT package_handle)
    message(FATAL_ERROR "package_handle_update_dependencies: no package handle specified")
    return()
  endif()
  package_dependency_changeset(${ARGN})
  ans(changeset)


  package_handle_dependencies("${package_handle}")
  ans(dependencies)
  
  map_new()
  ans(diff)

  map_keys(${changeset})
  ans(admissable_uris)
  
  foreach(admissable_uri ${admissable_uris})
    ## get previous value
    map_has(${dependencies} "${admissable_uri}")
    ans(has_constraint)

    if(has_constraint)
      map_tryget(${dependencies} "${admissable_uri}")
      ans(constraint)
      map_set(${diff} "${admissable_uri}" ${constraint})
    endif()

    ## set new value
    map_tryget(${changeset} ${admissable_uri})
    ans_extract(action)
    ans(constraint)



    if("${action}" STREQUAL "add")
      if(constraint)
        map_set(${dependencies} "${admissable_uri}" ${constraint})
      else()
        map_set(${dependencies} "${admissable_uri}" true)
      endif()
    elseif("${action}" STREQUAL "remove")
      map_remove(${dependencies} "${admissable_uri}")
    elseif("${action}" STREQUAL "conflict")
      map_set(${dependencies} ${admissable_uri} false)
    elseif("${action}" STREQUAL "optional")
      map_set(${dependencies} "${admissable_uri}")
    endif()    


  endforeach()
  return_ref(diff)
endfunction()








  ## parses the package descriptor from the filename
  ## a filename's version is separated by a hyphen
  function(package_descriptor_parse_filename file_name)
    string_take_regex(file_name "([^-]|(-[^0-9]))+")
    ans(default_id)
    set(rest "${file_name}")
    string_take_regex(file_name "\\-")
    string_take_regex(file_name "v")

    semver_format("${file_name}")
    ans(default_version)
    if(default_version STREQUAL "")
      set(default_version "0.0.0")
    endif()

    data("{id:$default_id, version:$default_version}")
    return_ans()
  endfunction()





  function(package_handle)
    map_tryget("${ARGN}" package_descriptor)
    ans(pd)
    map_tryget("${ARGN}" content_dir)
    ans(content_dir)

    path_qualify(content_dir)

    is_map("${pd}")
    ans(ismap)
    if(ismap AND content_dir AND IS_DIRECTORY "${content_dir}")
      return(${ARGN})
    endif()

    set(args ${ARGN})
    list_extract(args content_dir package_descriptor)

    path_qualify(content_dir)



    obj("${package_descriptor}")
    ans(pd)

    if(NOT pd)
      if(NOT IS_DIRECTORY "${content_dir}")
        return()
      endif()

      json_read("${content_dir}/package.cmake")
      ans(pd)
 
      if(NOT pd)
        return()
      endif()

    endif()


    map_new()
    ans(package_handle)
    map_set(${package_handle} package_descriptor ${pd})
    map_set(${package_handle} content_dir ${content_dir})
    return(${package_handle})

  endfunction()




## 
## ensures that the package_descriptor.package_handle exists
function(package_handle_dependencies package_handle)
  map_tryget(${package_handle} package_descriptor)
  ans(package_descriptor)
  if(NOT package_descriptor)
    map_new()
    ans(package_descriptor)
    map_set(${package_handle} package_descriptor ${package_descriptor})
  endif()
  map_tryget(${package_descriptor} dependencies)
  ans(dependencies)
  if(NOT dependencies)
    map_new()
    ans(dependencies)
    map_set(${package_descriptor} dependencies ${dependencies})
  endif()
  return_ref(dependencies)
endfunction()





function(package_handle_filter __handles uri)
      uri_coerce(uri)
  
      map_tryget(${uri} uri)
      ans(uri_string)

      ## return all handles if query uri is ?*
      if("${uri_string}" STREQUAL "?*")
        return_ref(${__handles})
      endif()

      foreach(package_handle ${${__handles}})
        map_tryget(${package_handle} uri)
        ans(package_uri)
        if("${package_uri}" STREQUAL "${uri_string}")
          return(${package_handle})
        endif()
      endforeach()

      assign(id_query = uri.params.id)
      if(id_query)
        set(result)
        foreach(package_handle ${${__handles}})
          assign(pid = package_handle.package_descriptor.id)
          if("${pid}_" STREQUAL "${id_query}_")
            list(APPEND result ${package_handle})
          endif() 
        endforeach()
        return_ref(result)
      endif()

      ## todo...

      return()


    endfunction()





## 
## 
## invokes a package descriptors hook in the correct context
## the pwd is set to content_dir and the var args are passed along
## the result of the hook or nothing is returned
## 
## the scope of the function inherits package_handle and package_descriptor
function(package_handle_invoke_hook package_handle path)
  assign(package_descriptor = package_handle.package_descriptor)
  assign(content_dir = package_handle.content_dir)
  assign(hook = "package_descriptor.${path}")
  if(NOT "${hook}_" STREQUAL "_")
    pushd(--force)
    if(EXISTS "${content_dir}")
      cd("${content_dir}")
    endif()
      call("${hook}"(${ARGN}))
      ans(res)
    popd(--force)
    return_ref(res)
  endif()
  return()
endfunction()




## 
## checks if every dependencies all_dependencies_materialized are set
##
function(package_handle_is_ready package_handle)
  map_tryget(${package_handle} materialization_descriptor)
  ans(is_materialized)
  if(NOT is_materialized)
    return(false)
  endif()
  map_tryget(${package_handle} dependencies)
  map_flatten(${__ans})
  ans(dependencies)
  set(all_dependencies_materialized true)
  foreach(dependency ${dependencies})
    map_get_map(${dependency} dependency_descriptor)
    ans(dependency_dependency_descriptor)
    map_tryget(${dependency_dependency_descriptor} is_ready)
    ans(dependency_all_dependencies_materialized)
    if(NOT dependency_all_dependencies_materialized)
      set(all_dependencies_materialized false)
      break()
    endif()
  endforeach()
  return_ref(all_dependencies_materialized)
endfunction()




##
##
##
function(archive_package_source)
  obj("{
    source_name:'archive',
    pull:'package_source_pull_archive',
    query:'package_source_query_archive',
    resolve:'package_source_resolve_archive',
    rate_uri:'package_source_rate_uri_archive'
  }")
  return_ans()
endfunction()






## package_source_pull_archive(<~uri> <?target_dir>)-><package handle>
##
## pulls the specified archive into the specified target dir
## 
  function(package_source_pull_archive uri)
    set(args ${ARGN})

    list_pop_front(args)
    ans(target_dir)

    path_qualify(target_dir)

    uri("${uri}")
    ans(uri)

    ## get package from uri

    package_source_resolve_archive("${uri}")
    ans(package_handle)

    if(NOT package_handle)
      error("could not resolve specified uri {uri.uri} to a package file")
      return()
    endif()

    assign(archive_path = package_handle.archive_descriptor.path)

    ## uncompress compressed file to target_dir
    pushd("${target_dir}" --create)
      ans(target_dir)
      uncompress("${archive_path}")
    popd()

    ## set content_dir
    map_set(${package_handle} content_dir "${target_dir}")


    return_ref(package_handle)
  endfunction()






  function(package_source_push_archive)
    if("${ARGN}" MATCHES "(.*);=>;?(.*)")
        set(source_args "${CMAKE_MATCH_1}")
        set(args "${CMAKE_MATCH_2}")
    else()
        set(source_args ${ARGN})
        set(args)
    endif()
    list_pop_front(source_args)
    ans(source)

    list_extract_flag(args --force)
    ans(force)

    list_pop_front(args)
    ans(target_file)

    ## used to pass format along
    list_extract_labelled_keyvalue(args --format)
    ans(format)


    path_qualify(target_file)

    path_temp()
    ans(temp_dir)

    assign(package_handle = source.pull(${source_args} "${temp_dir}"))
    assign(content_dir = package_handle.content_dir)# get content dir because pull may return somtehing different in case --reference is specified
    
    ## possibly generate a filename if ${target_file} is a directory
    if(IS_DIRECTORY "${target_file}")
        set(mimetype ${format})
        list_extract_labelled_value(mimetype --format)
        ans(mimetype)
        if(NOT mimetype)
            set(mimetype "application/x-gzip")
        endif()
        mime_type_get_extension("${mimetype}")
        ans(extension)
        format("{package_handle.package_descriptor.id}-{package_handle.package_descriptor.version}.{extension}")
        ans(filename)
        set(target_file "${target_file}/${filename}")
    endif()
    if(EXISTS "${target_file}")
        if(NOT force)
            error("cannot push: ${target_file} already exists")
            return()
        endif()
        if(IS_DIRECTORY "${target_file}")
            error("cannot push forced: ${target_file} is a directory")
            return()
        endif()
        rm("${target_file}")
    endif()

    ## compress all files in temp_dir into package
    pushd("${content_dir}")
      compress("${target_file}" "**" ${format})
    popd()

    ## cleanup
    rm("${temp_dir}")

    package_source_query_archive("${target_file}")
    ans(package_uri)


    ## set altered uri (now contains hash)
    map_set(${package_handle} uri "${package_uri}")

    return_ref(package_handle)
  endfunction()




  ## package_source_query_archive(<~uri>)->
  ## 
  function(package_source_query_archive uri)
    set(args ${ARGN})
        
    log("querying for local archive at {uri.uri}" --trace --function package_source_query_archive)

    list_extract_flag(args --package-handle)
    ans(return_package_handle)


    uri_coerce(uri)

    ## uri needs to be local
    map_tryget(${uri} normalized_host)
    ans(host)
    if(NOT host STREQUAL "localhost")
      return()
    endif()

    ## get the local_path of the uri
    uri_to_localpath("${uri}")
    ans(local_path)

    path_qualify(local_path)

    ## check that file exists and is actually a archive
    archive_isvalid("${local_path}")
    ans(is_archive)

    if(NOT is_archive)
        log("'{local_path}' is not an archive" --trace --function package_source_query_archive)
      return()
    endif()

    assign(expected_hash = uri.params.hash)
    ##
    checksum_file("${local_path}")
    ans(hash)


    if(NOT "${expected_hash}_" STREQUAL "_" AND NOT "${expected_hash}" STREQUAL "${hash}" )
        error("expected hash did not match hash of ${local_path}")
        return()
    endif()

    ## qualify uri to absolute path
    uri("${local_path}")
    ans(qualified_uri)
    uri_format("${qualified_uri}")
    ans(resource_uri)

    set(package_uri "${resource_uri}?hash=${hash}")
    log("found archive package at '{uri.uri}'" --function package_source_query_archive --trace)
    if(return_package_handle)
        set(package_handle)
        assign(!package_handle.uri = package_uri)
        assign(!package_handle.query_uri = uri.uri)
        assign(!package_handle.resource_uri = resource_uri)
        assign(!package_handle.archive_descriptor.hash = hash)
        assign(!package_handle.archive_descriptor.path = local_path)
        assign(!package_handle.archive_descriptor.pwd = pwd())
        return_ref(package_handle)
    endif()



    return_ref(package_uri)
  endfunction()







##
function(package_source_rate_uri_archive uri)
  uri_coerce(uri)
  uri_to_localpath("${uri}")
  ans(localpath)
  archive_isvalid("${localpath}")
  ans(isarchive)

  if(isarchive)
    return(999)
  endif()

  return(0)

endfunction()




## package_source_resolve_archive(<~uri>)-> <package handle>
## 
## resolves the specified uri to a unqiue immutable package handle 
function(package_source_resolve_archive uri)
    uri_coerce(uri)


    ## query for uri and return if no single uri is found
    package_source_query_archive("${uri}" --package-handle)
    ans(package_handle)
    list(LENGTH package_handle uri_count)
    if(NOT uri_count EQUAL 1)
      error("archive package source could not resolve a single immutable package for {uri.uri}")
      return()
    endif()

    ## uncompress package descriptor
    assign(archive_path = package_handle.archive_descriptor.path)

    ## search for the first package.cmake file in the archive 
    archive_match_files("${archive_path}" "([^;]+/)?package\\.cmake"  --single)
    ans(package_descriptor_path)    


    if(package_descriptor_path)
        archive_read_file("${archive_path}" "${package_descriptor_path}")
        ans(package_descriptor_content)
    endif()

    json_deserialize("${package_descriptor_content}")
    ans(package_descriptor)


    ## set package descriptor defaults
    assign(file_name = uri.file_name)
    package_descriptor_parse_filename("${file_name}")
    ans(default_package_descriptor)

    map_defaults("${package_descriptor}" "${default_package_descriptor}")
    ans(package_descriptor)


    ## update package handle
    assign(package_handle.package_descriptor = package_descriptor)
    assign(package_handle.archive_descriptor.package_descriptor_path = package_descriptor_path)

    return_ref(package_handle)
endfunction()





  function(bitbucket_package_source)
    obj("{
      source_name:'bitbucket',
      pull:'package_source_pull_bitbucket',
      query:'package_source_query_bitbucket',
      resolve:'package_source_resolve_bitbucket'
    }")
    return_ans()
  endfunction()







  function(package_source_pull_bitbucket uri)
    set(args ${ARGN})

    uri_coerce(uri)

    list_extract_flag(args --use-ssh)
    ans(use_ssh)

    package_source_resolve_bitbucket("${uri}")
    ans(package_handle)

    if(NOT package_handle)
      return()
    endif()

    list_pop_front(args)
    ans(target_dir)

    map_tryget(${package_handle} package_descriptor)
    ans(package_descriptor)

    assign(repo_descriptor = package_handle.bitbucket_descriptor.repository)

    map_tryget(${repo_descriptor} scm)
    ans(scm)

    assign(clone_locations = repo_descriptor.links.clone)
    map_new()
    ans(clone)
    foreach(clone_location ${clone_locations})
      map_import_properties(${clone_location} name href)
      map_set(${clone} ${name} ${href})
    endforeach()

    if(use_ssh)
      set(clone_method ssh)
    else()
      set(clone_method https)
    endif()

    map_tryget(${clone} "${clone_method}")
    ans(clone_uri)


    ## depending on scm pull git or hg
    if(scm STREQUAL "git")
      package_source_pull_git("${clone_uri}" "${target_dir}")
      ans(scm_package_handle)
    elseif(scm STREQUAL "hg")
      package_source_pull_hg("${clone_uri}" "${target_dir}")
      ans(scm_package_handle)
    else()
      message(FATAL_ERROR "scm not supported: ${scm}")
    endif()

    assign(package_handle.repo_descriptor = scm_package_handle.repo_descriptor)

    map_tryget("${scm_package_handle}" package_descriptor)
    ans(scm_package_descriptor)

    map_tryget("${scm_package_handle}" content_dir)
    ans(scm_content_dir)
    
    if(NOT scm_package_descriptor)
      map_new()
      ans(scm_package_descriptor)
    endif()  
    map_defaults("${package_descriptor}" "${scm_package_descriptor}")

    map_set("${package_handle}" content_dir "${scm_content_dir}")

    return_ref(package_handle)
  endfunction()





## `(<~uri> [--package-handle])->`
## 
##
## 
function(package_source_query_bitbucket uri)
  set(args ${ARGN})

  list_extract_flag(args --package-handle)
  ans(return_package_handle)

  uri_coerce(uri)

  uri_check_scheme(${uri} "bitbucket?")
  ans(scheme_ok)
  if(NOT scheme_ok)
    error("scheme {uri.scheme} is not supported - only bitbucket: or empty scheme allowed")
    return()
  endif()


  assign(segments = uri.normalized_segments)
  list_extract(segments user repo ref_type ref)
  assign(hash = uri.params.hash)

  if(NOT repo)
    set(repo *)
  endif()
  set(default false)
  if(NOT ref AND NOT ref_type)
    set(default true)
  endif()
  if(NOT ref AND NOT "${ref_type}" MATCHES "^(branches)|(tags)$")
    set(ref "${ref_type}")
    set(ref_type *)
  endif()
  if(NOT ref)
    set(ref "*")
  endif()


  map_new()
  ans(package_handles)

  if(hash)
    bitbucket_remote_ref("${user}" "${repo}" "commits" "${hash}")
    ans(remote_ref)

    map_import_properties(${remote_ref} ref_type ref)
    map_set(${package_handles} "bitbucket:${user}/${repo}/${name}/${ref_type}/${ref}" "${remote_ref}")
  elseif(user)
    if("${repo}" STREQUAL "*")
      ## get all repositories of user - no hash
      bitbucket_repositories("${user}")
      ans(names)

      foreach(name ${names})
        map_set(${package_handles} "bitbucket:${user}/${name}")
      endforeach()
    else()
      if(default)
        bitbucket_default_branch("${user}" "${repo}")
        ans(default_branch)
        if(default_branch)
          bitbucket_remote_ref("${user}" "${repo}" "branches" "${default_branch}")
          ans(ref)
          if(ref)
            map_tryget("${ref}" commit)
            ans(hash)
            set(package_uri "bitbucket:${user}/${repo}/branches/${default_branch}?hash=${hash}")
            map_set(${package_handles} "${package_uri}" ${ref})
          endif()
        endif()
      else()
        ## get all refs of the specified ref_type(s)
        bitbucket_remote_refs("${user}" "${repo}" "${ref_type}" "${ref}")
        ans(refs)

        foreach(ref ${refs})
          map_tryget(${ref} commit)
          ans(commit)
          map_tryget(${ref} ref_type)
          ans(ref_type)
          map_tryget(${ref} ref)
          ans(ref_name)

          map_set(${package_handles} "bitbucket:${user}/${repo}/${ref_type}/${ref_name}?hash=${commit}" ${ref})

        endforeach()

      else()

      endif()
    endif()
  else()
    error("you need to at least specify a bitbucket user")
    return()
  endif()


  ## create package handles if necessary

  map_keys(${package_handles})
  ans(keys)
  if(return_package_handle)
    set(map ${package_handles})
    set(package_handles)
    foreach(key ${keys})
      map_tryget(${map} ${key})
      ans(ref)
      set(package_handle)
      
      assign(!package_handle.uri = key)
      assign(!package_handle.query_uri = uri.uri)
      assign(!package_handle.bitbucket_descriptor.remote_ref = ref)
      list(APPEND package_handles ${package_handle})
    endforeach()

  else()
    set(package_handles ${keys})
  endif()
  return_ref(package_handles)
endfunction()






  function(package_source_resolve_bitbucket uri)
    uri_coerce(uri)

    package_source_query_bitbucket("${uri}" --package-handle)
    ans(package_handle)

    list(LENGTH package_handle count)
    if(NOT "${count}" EQUAL 1)
      error("could not resolve {uri.uri} to a single package handle (got {count}) ")
      return()
    endif()

    assign(user = package_handle.bitbucket_descriptor.remote_ref.user)
    assign(repo = package_handle.bitbucket_descriptor.remote_ref.repo)
    assign(hash = package_handle.bitbucket_descriptor.remote_ref.commit)
    assign(ref = package_handle.bitbucket_descriptor.remote_ref.ref)
    assign(ref_type = package_handle.bitbucket_descriptor.remote_ref.ref_type)

    if(NOT hash)
      error("could not resolve {uri.uri} to a immutable package")
      return()
    endif()

    bitbucket_api("repositories/${user}/${repo}" --json --silent-fail)
    ans(repository)
    if(NOT repository)
      error("could not get information on the bitbucket repository" --aftereffect)
      return()
    endif()
    assign(package_handle.bitbucket_descriptor.repository = repository)


    bitbucket_read_file("${user}" "${repo}" "${hash}" "package.cmake")
    ans(package_descriptor_content)
    set(package_descriptor)
    if(package_descriptor_content)
      json_deserialize("${package_descriptor_content}")
      ans(package_descriptor)
    endif()


    set(default_version ${hash})
    if("${ref_type}" STREQUAL "tags")
      set(default_version "${ref}")
    endif()

    map_defaults("${package_descriptor}" "{
      id:$repository.full_name,
      version:$default_version,
      description:$repository.description,
      owner:$repository.owner.display_name
    }")
    ans(package_descriptor)


    map_set(${package_handle} package_descriptor ${package_descriptor})

    return_ref(package_handle)

    return()
    uri("${uri}")
    ans(uri)
    
    ## query for a valid and single  bitbucket uris 
    package_source_query_bitbucket("${uri}")
    ans(valid_uri_string)
    list(LENGTH valid_uri_string uri_count)
    if(NOT uri_count EQUAL 1)
      return()
    endif()

    ## get owner repo and ref
    uri("${valid_uri_string}")
    ans(valid_uri)

    map_tryget(${valid_uri} normalized_segments)
    ans(segments)

    list_extract(segments owner repo ref)


    ## get repo descriptor (return if not found)
    set(api_uri "https://api.bitbucket.org/2.0")
    set(request_uri "${api_uri}/repositories/${owner}/${repo}" )

    http_get("${request_uri}" "" --json)
    ans(repo_descriptor)

    if(NOT repo_descriptor)
      return()
    endif()

    ## if no ref is set query the bitbucket api for main branch
    if("${ref}_" STREQUAL "_")
      ## get the main branch
      set(main_branch_request_uri "https://api.bitbucket.org/1.0/repositories/${owner}/${repo}/main-branch")

      http_get("${main_branch_request_uri}" "" --json)
      ans(response)
      assign(main_branch = response.name)
      set(ref "${main_branch}")  
    endif()

    set(path package.cmake)

    ## try to get an existing package descriptor by downloading from the raw uri
    set(raw_uri "https://bitbucket.org/${owner}/${repo}/raw/${ref}/${path}")

    http_get("${raw_uri}" "" --json)
    ans(package_descriptor)

    ## setup package descriptor default value

    map_defaults("${package_descriptor}" "{
      id:$repo_descriptor.full_name, 
      version:'0.0.0',
      description:$repo_descriptor.description
    }")
    ans(package_descriptor)

    ## response
    map_new()
    ans(result)
    map_set(${result} package_descriptor "${package_descriptor}")
    map_set(${result} uri "${valid_uri_string}")
    map_set(${result} repo_descriptor "${repo_descriptor}")

    return(${result})
  endfunction()




function(cached_package_source inner)
  set(args ${ARGN})
  list_pop_front(args)
  ans(cache_dir)

  if(NOT cache_dir)
    cmakepp_config(cache_dir)
    ans(cache_dir)
    set(cache_dir "${cache_dir}/package_cache")
  endif()

  path_qualify(cache_dir)

  set(this)
  assign(!this.cache_dir = cache_dir)
  assign(!this.inner = inner)

  assign(!this.indexed_store = indexed_store("${cache_dir}/store"))
  assign(index = this.indexed_store.index_add("package_handle.uri"))
  assign(index = this.indexed_store.index_add("package_handle.query_uri"))
  assign(index = this.indexed_store.index_add("package_handle.package_descriptor.id"))
  assign(this.indexed_store.key = "'[](container) ref_nav_get({{container}} package_handle.uri)'")


  assign(!this.clear_cache = 'package_source_cached_clear_cache')
  assign(!this.query = 'package_source_query_cached')
  assign(!this.resolve = 'package_source_resolve_cached')
  assign(!this.pull = 'package_source_pull_cached')

  return_ref(this)
endfunction()

function(package_source_cached_clear_cache)
  this_get(cache_dir)
  rm(-r "${cache_dir}")
endfunction()




function(package_source_pull_cached uri)
  set(args ${ARGN})
  list_extract_labelled_keyvalue(args --refresh)
  ans(refresh)

  uri_coerce(uri)

  list_pop_front(args)
  ans(target_dir)
  path_qualify(target_dir)


  package_source_resolve_cached("${uri}" ${refresh} --cache-container)
  ans(cache_container)

  if(NOT cache_container)
    return()
  else()
    assign(uri = cache_container.package_handle.uri)
    uri_coerce(uri)
  endif()


  this_get(cache_dir)
  map_tryget(${cache_container} cache_key)
  ans(cache_key)

  set(content_dir "${cache_dir}/content/${cache_key}")
  if(NOT EXISTS "${content_dir}")
    #message(FORMAT "PULL_MISS {uri.uri}")
    ## pull
    assign(package_handle = this.inner.pull("${uri}" "${content_dir}"))
    if(NOT package_handle)
      error("failed to pull {uri.uri} after cache miss")
      return()
    endif()
  else()
    #message(FORMAT "PULL_HIT {uri.uri}")
    assign(package_handle = cache_container.package_handle)
  endif()
  
  cp_dir("${content_dir}" "${target_dir}")
  assign(package_handle.content_dir = target_dir )

  return_ref(package_handle)
endfunction()




function(package_source_query_cached uri)
  set(args ${ARGN})
  list_extract_flag(args --cache-container)
  ans(return_cache_container)
  list_extract_flag(args --package-handle)
  ans(return_package_handle)
  list_extract_flag(args --refresh)
  ans(refresh)
  uri_coerce(uri)

  ## find stored package handles
  set(cache_containers)
  if(NOT refresh)
    assign(query_string = uri.uri)
    assign(id_query = uri.params.id)
    assign(container_keys = this.indexed_store.find_keys(
      "package_handle.query_uri==${query_string}"
      "package_handle.uri==${query_string}"
      "package_handle.package_descriptor.id==${id_query}"
    ))
    foreach(container_key ${container_keys})
      assign(container = this.indexed_store.load("${container_key}"))
      map_set(${container} cache_key ${container_key})
      list(APPEND cache_containers ${container})
    endforeach()
  endif()

  ## if none were found query for them and save them
  if(NOT cache_containers)
    #message(FORMAT "QUERY_MISS {uri.uri}")
    assign(package_handles = this.inner.query("${uri}" --package-handle))
    foreach(package_handle ${package_handles})
      map_new()
      ans(container)
      map_set(${container} package_handle ${package_handle})
      assign(cache_key = this.indexed_store.save("${container}"))
      map_set(${container} cache_key ${cache_key})
      list(APPEND cache_containers ${container})
    endforeach()
  else()
    #message(FORMAT "QUERY_HIT {uri.uri}")

  endif()

  if(return_cache_container)
    return_ref(cache_containers)
  endif()

  list_select_property(cache_containers package_handle)
  ans(package_handles)

  if(return_package_handle)
    return_ref(package_handles)
  endif()

  list_select_property(package_handles uri)
  ans(package_uris)

  return_ref(package_uris)
endfunction()




function(package_source_resolve_cached uri)
  set(args ${ARGN})
  list_extract_labelled_keyvalue(args --refresh)
  ans(refresh)
  list_extract_flag(args --cache-container)
  ans(return_cache_container)
  
  uri_coerce(uri)

  package_source_query_cached("${uri}" ${refresh} --cache-container)
  ans(cache_container)


  if("${cache_container}" MATCHES ";")  
    error("multiple matches found")
    return()
  endif()

  set(is_resolved false)

  if(cache_container)
    map_tryget(${cache_container} is_resolved)
    ans(is_resolved)
    assign(uri = cache_container.package_handle.uri)
    ans(uri)
    uri_coerce(uri)
  else()
    map_new()
    ans(cache_container)
  endif()

  if(NOT is_resolved)

    assign(package_handle = this.inner.resolve("${uri}"))
    if(NOT package_handle)
      error("cache package source: inner package source could not resolve {uri.uri}")
      return()
    endif()
    map_set(${cache_container} is_resolved true)
    map_set(${cache_container} package_handle ${package_handle})
    assign(success = this.indexed_store.save("${cache_container}"))
  else()
    #message(FORMAT "RESOLVE_HIT {uri.uri}")
  endif()

  if(return_cache_container)
    return_ref(cache_container)
  endif()


  map_tryget(${cache_container} package_handle)
  ans(package_handle)

  return_ref(package_handle)
endfunction()





  function(composite_package_source source_name)
    set(sources ${ARGN})
    obj("{
      source_name:$source_name,
      query:'package_source_query_composite',
      resolve:'package_source_resolve_composite',
      pull:'package_source_pull_composite',
      add:'composite_package_source_add'
    }")
    ans(this)

    foreach(source ${sources})
      composite_package_source_add(${source})      
    endforeach()
    return_ref(this)
  endfunction()





## adds a package soruce to the composite package soruce
function(composite_package_source_add source)
  map_tryget(${source} source_name)
  ans(source_name)

  if(NOT source_name)
    message(FATAL_ERROR "source_name needs to be set")
  endif()
  assign("!this.children.${source_name}" = source)
  return()
endfunction()




  ## package_source_pull_composite(<~uri?>) -> <package handle>
  ##
  ## pulls the specified package from the best matching child sources
  ## returns the corresponding handle on success else nothing is returned
  function(package_source_pull_composite uri)
    set(args ${ARGN})

    uri("${uri}")
    ans(uri)

    ## resolve package and return if none was found
    package_source_resolve_composite("${uri}")
    ans(package_handle)

    if(NOT package_handle)
      return()
    endif()

    ## get package source and uri from handle
    ## because current uri might not be fully qualified
    map_tryget(${package_handle} package_source_name)
    ans(package_source_name)

    if(NOT package_source_name)
      message(FATAL_ERROR "no package source name in package handle")
    endif()

    assign(package_source = "this.children.${package_source_name}")
    if(NOT package_source)
      message(FATAL_ERROR "unknown package source ${package_source_name}")
    endif()
    map_tryget(${package_handle} uri)
    ans(package_uri)

    ## use the package package source to pull the correct package
    ## and return the result
    assign(package_handle = package_source.pull("${package_uri}" ${args}))

    return_ref(package_handle)
  endfunction()





## package_source_query_composite(<~uri> [--package-handle]) -> <uri..>|<pacakage handle...>
##
## --package-handle  flag specifiec that not a uri but a <package handle> should be returned
##
## queries the child sources (this.children) for the specified uri
## this is done by first rating and sorting the sources depending on 
## the uri so the best source is queryied first
## if a source returns a rating of 999 all other sources are disregarded
function(package_source_query_composite uri)
  uri_coerce(uri)

  set(args ${ARGN})

  list_contains(args --package-handle)
  ans(return_package_handle)

  

  ## rate and sort sources for uri    
  this_get(children)
  map_values(${children})
  ans(children)

  rated_package_source_sort("${uri}" ${children})
  ans(rated_children)


  ## loop through every source and query it for uri
  ## append results to result. 
  ## if the rating is 0 break because all following sources will
  ## also be 0 and this indicates that the source is incompatible 
  ## with the uri
  ## if the rating is 999 break after querying the source as this 
  ## source has indicated that it is solely responsible for this uri
  set(result)
  while(true)
    if(NOT rated_children)
      break()
    endif()

    list_pop_front(rated_children)
    ans(current)

    map_tryget(${current} rating)
    ans(rating)
    ## source and all rest sources are incompatible 
    if(rating EQUAL 0)
      break()
    endif()

    map_tryget(${current} source)
    ans(source)
    ## query the source
    ## args (especially --package-handle will be passed along)
    assign(current_result = source.query("${uri}" ${args}))
    if(return_package_handle)
      foreach(handle ${current_result})
        map_tryget(${source} source_name)
        ans(source_name) 
        map_set(${handle} package_source_name ${source_name})
      endforeach()
    endif()
    ## append to result
    list(APPEND result ${current_result})
    ## source has indicated it is solely responsible for uri
    ## all further sources are disregarded
    if(NOT rating LESS  999)
      break()
    endif()
  endwhile()
  return_ref(result)
endfunction()






## function used to rate a package source and a a uri
## default rating is 1 
## if a scheme of uri matches the source_name property
## of a package source the rating is 999
## else package_source's rate_uri function is called
## if it exists which can return a custom rating
function(package_source_rate_uri package_source uri)
  uri("${uri}")
  ans(uri)

  set(rating 1)

  map_tryget(${uri} schemes)
  ans(schemes)
  map_tryget(${package_source} source_name)
  ans(source_name)

  ## contains scheme -> rating 999
  list_contains(schemes "${source_name}")
  ans(contains_scheme)

  if(contains_scheme)
    set(rating 999)
  endif()

  ## package source may override default behaviour
  map_tryget(${package_source} rate_uri)
  ans(rate_uri)
  if(rate_uri)
    call(source.rate_uri(${uri}))
    ans(rating)
  endif()

  return_ref(rating)
endfunction()




  ## package_source_resolve_composite(<~uri>) -> <package handle>
  ## returns the package handle for the speciified uri
  ## the handle's package_source property will point to the package source used

  function(package_source_resolve_composite uri)
    set(args ${ARGN})

#    message(FORMAT "package_source_resolve_composite: {uri.uri}")
    uri_coerce(uri)

    ## query composite returns the best matching package_uris first
    ## specifiying --package-handle returns the package handle as 
    ## containing the package_uri and the package_source
    package_source_query_composite("${uri}" --package-handle)
    ans(package_handles)

    ## loops through every package handle and tries to resolve
    ## it. returns the handle on the first success
    while(true)

      if(NOT package_handles)
        return()
      endif()

      list_pop_front(package_handles)
      ans(package_handle)
      
      map_tryget(${package_handle} package_source_name)
      ans(package_source_name)

      assign(package_source = "this.children.${package_source_name}")
      
      if(NOT package_source)
        message(FATAL_ERROR "package handle missing package_source property")
      endif()

      map_tryget(${package_handle} uri)
      ans(uri)
      assign(package_handle = package_source.resolve("${uri}"))

      if(package_handle)
        ## copy over package source to new package handle
        assign(package_handle.package_source_name = package_source_name)
       # assign(package_handle.rating = source_uri.rating)
        return_ref(package_handle)
      endif()

    endwhile()
    return()
  endfunction() 

  





  ## creates rated package sources from the specified sources
  ## { rating:<number>, source:<package source>}
  function(rated_package_sources)
    set(result)
    foreach(source ${ARGN})
      map_new() 
      ans(map)
      map_set(${map} source ${source})
      package_source_rate_uri(${source} ${uri})
      ans(rating)
      map_set(${map} rating ${rating}) 
      list(APPEND result ${map})
    endforeach()
    return_ref(result)
  endfunction()






  ## compares two rated package sources and returns a number
  ## pointing to the lower side
  function(rated_package_source_compare lhs rhs)
      map_tryget(${rhs} rating)
      ans(rhs)
      map_tryget(${lhs} rating)
      ans(lhs)
      math(EXPR result "${lhs} - ${rhs}")
      return_ref(result)
  endfunction()





  ## sorts the rated package sources by rating
  ## and returns them
  function(rated_package_source_sort uri)
    rated_package_sources(${ARGN})
    ans(rated_sources)


    list_sort(rated_sources rated_package_source_compare)
    ans(rated_sources)
    return_ref(rated_sources)
  endfunction()







function(default_package_source)
  map_tryget(global default_package_source)
  ans(result)
  if(NOT result)
    set(sources)

    path_package_source()
    ans_append(sources)
    
    archive_package_source()
    ans_append(sources)

    webarchive_package_source()
    ans_append(sources)

    host_package_source()
    ans_append(sources)

    find_package(Git)
    find_package(Hg)
    find_package(Subversion)

    if(GIT_FOUND)
      github_package_source()
      ans_append(sources)
    endif()    

    if(GIT_FOUND AND HG_FOUND)
      bitbucket_package_source()
      ans_append(sources)
    endif()
    
    if(GIT_FOUND)
      git_package_source()
      ans_append(sources)
    endif()

    if(HG_FOUND)
      hg_package_source()
      ans_append(sources)
    endif()

    if(SUBVERSION_FOUND)
      svn_package_source()
      ans_append(sources)
    endif()

    composite_package_source("" ${sources})
    ans(inner)

    set(default_package_source ${inner})
#    cached_package_source("${inner}")
 #   ans(default_package_source)

    map_set(global default_package_source ${default_package_source})
  endif()
  function(default_package_source)
    map_get(global default_package_source)
    return_ans()
  endfunction()
  return_ans()  
endfunction()





## sets the default package source
function(default_package_source_set source)
  package_source(${source} ${ARGN})
  ans(source)
  if(NOT source)
    message(FATAL_ERROR "invalid package source")
  endif()
  map_set(global default_package_source "${source}")
endfunction()




## pull_package(<~uri> <?target dir>|[--reference]) -> <package handle>
##
## --reference flag causes pull to return an existing content_dir in package handle if possible
##             <null> is returned if pulling a reference is not possbile
##
## <target dir> the <unqualified path< were the package is to be pulled to
##              the default is the current directory
##
##  pull the specified package to the target location. the package handle contains
##  meta information about the package like the package uri, package_descriptor, content_dir ...
function(pull_package)
  default_package_source()
  ans(source)
  call(source.pull(${ARGN}))
  return_ans()
endfunction()





## query_package(<~uri> [--package-handle]) -> <uri string>|<package handle>
## queries the default package source for a package
function(query_package)
  default_package_source()
  ans(source)
  call(source.query(${ARGN}))
  return_ans()
endfunction()





## resolve_package(<~uri>) -> <package handle>
## 
function(resolve_package)
  default_package_source()
  ans(source)
  call(source.resolve(${ARGN}))
  return_ans()
endfunction()







  function(directory_package_source source_name directory)
    path_qualify(directory)
    obj("{
      source_name:$source_name,
      directory:$directory,
      pull:'package_source_pull_directory',
      query:'package_source_query_directory',
      resolve:'package_source_resolve_directory'
    }")
    return_ans()
  endfunction()





  ## package_source_pull_directory(<~uri> [--reference]) -> <package handle>
  ## --reference flag 
  function(package_source_pull_directory uri)
    set(args ${ARGN})

    package_source_resolve_directory("${uri}")
    ans(package_handle)

    if(NOT package_handle)
      return()
    endif()

    list_extract_flag(args --reference)
    ans(reference)

    if(NOT reference)
      list_pop_front(args)
      ans(target_dir)
      path_qualify(target_dir)
    
      map_tryget(${package_handle} content_dir)
      ans(source_dir)

      cp_dir("${source_dir}" "${target_dir}")
      map_set(${package_handle} content_dir "${target_dir}")  
    endif()
    
    return_ref(package_handle)
  endfunction()





  ## package_source_query_directory(<~uri>) -> <uri string>
  function(package_source_query_directory uri)
    set(args ${ARGN})

    list_extract_flag(args --package-handle)
    ans(return_package_handle)

    this_get(directory)
    this_get(source_name)

    uri_coerce(uri)

    ## return if scheme is either empty or equal to source_name       
    assign(scheme = uri.scheme)

    uri_check_scheme("${uri}" "${source_name}?")
    ans(scheme_ok)
    if(NOT scheme_ok)
      error("expected either ${source_name} or nothing as scheme. {uri.uri}")
      return()
    endif() 

    map_tryget(${uri} segments)
    ans(segments)
    list(LENGTH segments segment_length)

    ## if uri has a single segment it is interpreted as a hash
    if(segment_length EQUAL 1 AND IS_DIRECTORY "${directory}/${segments}")
      set(result "${source_name}:${segments}")
    elseif(NOT segment_length EQUAL 0)
      ## multiple segments are not allowed and are a invliad uri
      set(result)
    else()
      ## else parse uri's query (uri starts with ?)

      map_tryget(${uri} query)
      ans(query)
      if("${query}" MATCHES "=")
        ## if query contains an equals it is a map
        ## else it is a value
        map_tryget(${uri} params)
        ans(query)        
      endif()

      ## empty query returns nothing
      if(query STREQUAL "")
        return()
      endif()

      ## read all package indices
      file(GLOB folders RELATIVE "${directory}" "${directory}/*")

      is_map("${query}")
      ans(ismap)
    
      ## query may be a * which returns all packages 
      ## or a regex /[regex]/
      ## or a map which will uses the properties to match values
      if(query STREQUAL "*")
        set(result)
        foreach(folder ${folders})
          list(APPEND result "${source_name}:${folder}")
        endforeach()
      elseif("${query}" MATCHES "^/(.*)/$")
        ## todo
        set(result)
      elseif(ismap)
        ## todo
        set(result)
      endif()
    endif()

    if(return_package_handle)
      set(package_handles)
      foreach(item ${result})
        set(package_handle)
        assign(!package_handle.uri = item)
        assign(!package_handle.query_uri = uri.uri)
        list(APPEND package_handles ${package_handle})
      endforeach()
      set(result ${package_handles})
    endif()

    return_ref(result)

  endfunction()






## package_source_resolve_directory(<~uri>) -> <package handle>
  function(package_source_resolve_directory uri)
    uri("${uri}")
    ans(uri)

    package_source_query_directory("${uri}")
    ans(valid_uri_string)

    list(LENGTH valid_uri_string count)
    if(NOT count EQUAL 1)
      return()
    endif()

    ## if uri contains query return
    map_tryget(${uri} query)
    ans(query)
    if(NOT "${query}_" STREQUAL "_")
      return()
    endif()

    this_get(directory)

    ## parse uri
    uri("${valid_uri_string}")
    ans(uri)

    map_tryget(${uri} scheme_specific_part)
    ans(subdir)

    set(content_dir "${directory}/${subdir}")

    package_handle("${content_dir}")
    ans(package_handle)

    map_tryget("${package_handle}" package_descriptor)
    ans(package_descriptor)

    map_defaults("${package_descriptor}" "{
      id:$subdir,
      version:'0.0.0'
    }")
    ans(package_descriptor)

    ## response
    map_new()
    ans(package_handle)
    map_set(${package_handle} package_descriptor "${package_descriptor}")
    map_set(${package_handle} uri "${valid_uri_string}")
    map_set(${package_handle} content_dir "${content_dir}")

    return_ref(package_handle)
  endfunction()







  function(git_package_source)
    obj("{
      source_name:'gitscm',
      pull:'package_source_pull_git',
      query:'package_source_query_git',
      resolve:'package_source_resolve_git'
    }")
    return_ans()
  endfunction()





## package_source_pull_git(<~uri> <path?>) -> <package handle>
##
## pulls the package described by the uri  into the target_dir
## e.g.  package_source_pull_git("https://github.com/toeb/cutil.git?ref=devel")
  function(package_source_pull_git uri)
    set(args ${ARGN})

    list_pop_front(args)
    ans(target_dir)

    path_qualify(target_dir)

    package_source_resolve_git("${uri}")
    ans(package_handle)

    if(NOT package_handle)
        return()
    endif()


    assign(remote_uri = package_handle.scm_descriptor.ref.uri)
    assign(revision = package_handle.scm_descriptor.ref.revision)

    git_cached_clone("${remote_uri}" "${target_dir}" --ref "${revision}" ${args})
    ans(target_dir)

    map_set(${package_handle} content_dir "${target_dir}")

    return_ref(package_handle)
  endfunction()   






## returns a list of valid package uris which contain the scheme gitscm
## you can specify a query for ref/branch/tag by adding ?ref=* or ?ref=name
## only ?ref=* returns multiple uris
  function(package_source_query_git uri)
    set(args ${ARGN})

    list_extract_flag(args --package-handle)
    ans(return_package_handle)

    uri_coerce(uri)

    log("git_package_source: querying for {uri.uri}" --trace)


    uri_qualify_local_path("${uri}")
    ans(uri)

    uri_format("${uri}" --no-query)
    ans(remote_uri)

    ## check if remote exists
    git_remote_exists("${remote_uri}")
    ans(remote_exists)


    ## remote does not exist
    if(NOT remote_exists)
      log("git_package_source: remote '{remote_uri}' does not exist")
      return()
    endif()

    ## get ref and check if it exists
    assign(ref = uri.params.ref)
    assign(branch = uri.params.branch)  
    assign(tag = uri.params.tag)
    assign(rev = uri.params.rev)

    set(ref ${ref} ${branch} ${tag})
    list_pop_front(ref)
    ans(ref)

    set(remote_refs)
    if(NOT "${rev}_" STREQUAL "_")
      ## todo validate rev furhter??
      if(NOT "${rev}" MATCHES "^[a-fA-F0-9]+$")
         error("git_package_source: invalid revision for {uri.uri}: '{rev}'")
        return()
      endif()

      obj("{
        revision:$rev,
        type:'rev',
        name:$rev,
        uri:$remote_uri  
      }")

      ans(remote_refs)
    elseif("${ref}_" STREQUAL "*_")
      ## get all remote refs and format a uri for every found tag/branch
      git_remote_refs("${remote_uri}")
      ans(refs)

      foreach(ref ${refs})
        map_tryget(${ref} type)
        ans(ref_type)
        if("${ref_type}" MATCHES "(tags|heads)")
          list(APPEND remote_refs ${ref})
        endif()
      endforeach()
    elseif(NOT "${ref}_" STREQUAL "_")
      ## ensure that the specified ref exists and return a valid uri if it does
      git_remote_ref("${remote_uri}" "${ref}" "*")
      ans(remote_refs)
    else()

      git_remote_ref("${remote_uri}" "HEAD" "*")
      ans(remote_refs)
    endif()


    ## generate result from the scm descriptors
    set(results)
    foreach(remote_ref ${remote_refs})
      git_scm_descriptor("${remote_ref}")
      ans(scm_descriptor)
      assign(rev = scm_descriptor.ref.revision)
      set(result "${remote_uri}?rev=${rev}")
      log("git_package_source: query {uri.uri} found {result}" --trace)
      if(return_package_handle)
        set(package_handle)
        assign(!package_handle.uri = result)
        assign(!package_handle.scm_descriptor = scm_descriptor)
        assign(!package_handle.query_uri = uri.uri)
        set(result ${package_handle})
      endif()
      list(APPEND results ${result})
    endforeach()


    
    return_ref(results)
  endfunction()




## returns a pacakge descriptor for the specified git uri 
## takes long for valid uris because the whole repo needs to be checked out
function(package_source_resolve_git uri)
  set(args ${ARGN})

  uri_coerce(uri)

  package_source_query_git("${uri}" --package-handle)
  ans(package_handle)

  list(LENGTH package_handle count)
  
  if(NOT "${count}" EQUAL 1)
    error("could not get a unqiue uri for '{uri.uri}' (got {count})")
    return()
  endif()

  assign(remote_uri = package_handle.scm_descriptor.ref.uri)
  assign(rev = package_handle.scm_descriptor.ref.revision)

  git_cached_clone("${remote_uri}" --ref ${rev} --read package.cmake)
  ans(package_descriptor_content)

  json_deserialize("${package_descriptor_content}")
  ans(package_descriptor)

 # print_vars(uri.uri package_descriptor_content)

  map_tryget(${uri} file_name)
  ans(default_id)

  map_defaults("${package_descriptor}" "{
    id:$default_id,
    version:'0.0.0'
  }")
  ans(package_descriptor)

  map_set(${package_handle} package_descriptor ${package_descriptor})

  return_ref(package_handle)
endfunction()





  function(github_package_source)
    obj("{
      source_name:'github',
      pull:'package_source_pull_github',
      query:'package_source_query_github',
      resolve:'package_source_resolve_github'
    }")
    return_ans()
  endfunction()






## package_source_pull_github(<~uri> <?target_dir>) -> <package handle>
function(package_source_pull_github uri)
  set(args ${ARGN})
  uri_coerce(uri)
  log("pulling {uri.uri}" --trace --function package_source_pull_github)  

  ## get package descriptor 
  package_source_resolve_github("${uri}")
  ans(package_handle)
  if(NOT package_handle)
    return()
  endif()

  ## get path
  list_pop_front(args)
  ans(target_dir)
  path_qualify(target_dir)

  ## retreive the hidden/special repo_descriptor
  ## to gain access to the clone url
  map_tryget(${package_handle} github_descriptor)
  ans(repo_descriptor)

  map_tryget(${package_handle} package_descriptor)
  ans(package_descriptor)

  ## alternatives git_url/clone_url
  map_tryget(${repo_descriptor} clone_url)
  ans(clone_url)

  package_source_pull_git("${clone_url}" "${target_dir}")
  ans(scm_package_handle)

  if(NOT scm_package_handle)
    return()
  endif()

  map_tryget("${scm_package_handle}" package_descriptor)
  ans(scm_package_descriptor)

  assign(package_handle.repo_descriptor = scm_package_handle.repo_descriptor)

  map_defaults("${package_descriptor}" "${scm_package_descriptor}")

  map_tryget("${scm_package_handle}" content_dir)
  ans(scm_content_dir)

  map_set("${package_handle}" content_dir "${scm_content_dir}")

  return_ref(package_handle)

endfunction()




## package_source_query_github([--package-handle])->
##
##
## "" => null 
## <github user> => <github user>/*
## <github user>/* => repo list
## <github user>/<repository> => <github user>/<repository>/branches/<default branch>?hash=<commit sha>
## <github user>/<repository>/* => <github user>/<repository>/(branches|tags)/<name>?hash=<commit sha> ...
## <github user>/<repository>/<ref name> => <github user>/<repository>/branches/<ref name>?hash=<commit sha>
## <github user>/<repository>/<ref type>/* => <github user>/<repository>/<ref type>/<ref name>?hash=<commit sha>
## <github user>/<repository>/<ref type>/<ref => <github user>/<repository>/<ref type>/<ref name>?hash=<commit sha>
function(package_source_query_github uri)
  set(args ${ARGN})


  list_extract_flag(args --package-handle)
  ans(return_package_handle)


  ## parse uri and extract the two first segments 
  uri_coerce(uri)

  log("querying for '{uri.uri}'" --trace --function package_source_query_github)


  assign(scheme = uri.scheme)
  uri_check_scheme("${uri}" "github?")
  ans(scheme_ok)
  if(NOT scheme_ok)
    log("invalid schmeme: '{uri.scheme}'" --trace --function package_source_query_github)
    return()
  endif()


  assign(segments = uri.normalized_segments)
  list_extract(segments user repo ref_type ref)
  
  set(repo_query)
  if("${repo}_" STREQUAL "*_")
    set(repo)
    set(repo_query *)
  endif()

  assign(hash = uri.params.hash)
  set(package_handles)

  if(hash)
    github_remote_refs("${user}" "${repo}" commits "${hash}")
    ans(res)
    map_format("github:${user}/${repo}?hash=${hash}")
    ans(package_handles)
  elseif(user AND repo AND ref_type)
    if(NOT "${ref_type}" MATCHES "\\*|branches|tags" )
      set(ref_query ${ref_type})
      set(ref_type *)
    else()
      set(ref_query "*")
    endif()

    github_remote_refs("${user}" "${repo}" "${ref_type}" "${ref_query}")
    ans(refs)
    foreach(current_ref ${refs})
      map_format("github:${user}/${repo}/{current_ref.ref_type}/{current_ref.ref}?hash={current_ref.commit}")
      ans_append(package_handles)
    endforeach()
  elseif(user AND repo)
    github_repository("${user}" "${repo}")
    ans(repository)
    assign(default_branch = repository.default_branch)
    github_remote_refs("${user}" "${repo}" "branches" "${default_branch}")
    ans(remote_ref)
    if(remote_ref)
      map_format("github:{repository.full_name}/branches/{repository.default_branch}?hash={remote_ref.commit}")
      ans(package_handles)
    endif()
    
  elseif(user)
    ## only  user results in non unique ids which have to be quried again
    github_repository_list("${user}")
    ans(repositories)
    set(package_handles)
    foreach(repo ${repositories})
      map_tryget(${repo} full_name)
      ans(repo_name)
      list(APPEND package_handles "github:${repo_name}")
    endforeach()
  else()
    ## no user (not queried) too many results
  endif()
  list(LENGTH package_handles count) 
  log("'{uri.uri}' resulted in {count} dependable uris" --trace --function package_source_query_github)

  if(return_package_handle)
    set(uris ${package_handles})
    set(package_handles)
    foreach(github_url ${uris})
      set(package_handle)
      assign(!package_handle.uri = github_url)
      assign(!package_handle.query_uri = uri.uri)
      list(APPEND package_handles ${package_handle})
    endforeach()
    return_ref(package_handles)
  endif()

    return_ref(package_handles)

endfunction()








  ## package_source_resolve_github() -> <package handle> {}
  ##
  ## resolves the specifie package uri 
  ## and if uniquely identifies a package 
  ## returns its pacakge descriptor
  function(package_source_resolve_github uri)
    uri_coerce(uri)

    log("querying for '{uri.uri}'" --trace --function package_source_resolve_github)


    package_source_query_github("${uri}" --package-handle)
    ans(package_handle)

    list(LENGTH package_handle count)
    if(NOT "${count}" EQUAL 1)
        error("could not resolve '{uri.uri}' to a unique package (got {count})" --function package_source_resolve_github)
        return()
    endif() 

    assign(package_uri = package_handle.uri)
    uri("${package_uri}")
    ans(package_uri)
    assign(hash = package_uri.params.hash)
    if(NOT hash)
        error("package uri is not unique. requires a hash param: '{uri.uri}'" --function package_source_resolve_github)
        return()
    endif()

    assign(user = package_uri.normalized_segments[0])
    assign(repo = package_uri.normalized_segments[1])
    assign(ref_type = package_uri.normalized_segments[2])
    assign(ref_name = package_uri.normalized_segments[3])


    ## get the repository descriptor
    github_api("repos/${user}/${repo}" --json)
    ans(repo_descriptor)
    if(NOT repo_descriptor)
        error("could not resolve repository descriptor" --function package_source_resolve_github)
        return()
    endif()



    ## try to get the package descriptor remotely
    github_get_file("${user}" "${repo}" "${hash}" "package.cmake" --silent-fail)
    ans(content)
    json_deserialize("${content}")
    ans(package_descriptor)


    ## map default values on the packge descriptor 
    ## using the information from repo_descriptor
    assign(default_description = repo_descriptor.description)

    map_defaults("${package_descriptor}" "{
      id:$repo,
      version:'0.0.0',
      description:$default_description
    }")
    ans(package_descriptor)
    


    ## response
    map_set(${package_handle} package_descriptor "${package_descriptor}")
    map_set(${package_handle} github_descriptor "${repo_descriptor}")

    log("resolved package handle for '{package_handle.query_uri}': '{package_handle.uri}'" --trace --function package_source_resolve_github)

    return_ref(package_handle)
  endfunction()





  function(hg_package_source)
    obj("{
      source_name:'hgscm',
      pull:'package_source_pull_hg',
      query:'package_source_query_hg',
      resolve:'package_source_resolve_hg'
    }")
    return_ans()
  endfunction()






## package_source_pull_hg
##
## 
  function(package_source_pull_hg uri)
    set(args ${ARGN})

    uri("${uri}")
    ans(uri)


    list_pop_front(args)
    ans(target_dir)

    path_qualify(target_dir)
    
    package_source_resolve_hg("${uri}")
    ans(package_handle)



    if(NOT package_handle)
        return()
    endif()



    assign(remote_uri = package_handle.scm_descriptor.ref.uri)
    assign(hash = package_handle.scm_descriptor.ref.hash)

    hg_cached_clone("${remote_uri}" --ref "${hash}" "${target_dir}")
    ans(target_dir)

    map_set(${package_handle} content_dir "${target_dir}")


    return_ref(package_handle)
  endfunction()




## package_source_query_hg(<~uri>) -> <uri>|<package handle>

  function(package_source_query_hg uri)
    set(args ${ARGN})
    list_extract_flag(args --package-handle)
    ans(return_package_handle)

    uri("${uri}")
    ans(uri)

    uri_qualify_local_path("${uri}")
    ans(uri)

   # uri_format("${uri}" --no-query --remove-scheme hgscm)
    uri_format("${uri}" --no-query)
    ans(remote_uri)

    ## check if remote exists
    hg_remote_exists("${remote_uri}")
    ans(remote_exists)
    if(NOT remote_exists)
      return()
    endif()

    ## get ref 
    assign(rev = uri.params.rev)
    assign(ref = uri.params.ref)
    assign(branch = uri.params.branch)
    assign(tag = uri.params.tag)
    set(ref ${ref} ${branch} ${tag})
    list_pop_front(ref)
    ans(ref)

    hg_cached_clone("${remote_uri}" --readonly)
    ans(repo_dir)


    if(NOT ref AND NOT rev)
      set(ref "tip")
    endif()

    pushd("${repo_dir}")
    set(refs)
    if("${rev}" MATCHES "[0-9A-Fa-f]+" )
      map_new()
      ans(refs)
      map_set(${refs} inactive false)
      map_set(${refs} name ${rev})
      map_set(${refs} number 0)
      map_set(${refs} hash ${rev})
      map_set(${refs} type "rev")
    elseif(NOT "${ref}_" STREQUAL "_")
      hg_get_refs()
      ans(refs)
      if(NOT "${ref}" STREQUAL "*")
        set(selected_refs)
        foreach(current_ref ${refs})
          map_tryget(${current_ref} name)
          ans(name)
          if("${name}" STREQUAL "${ref}")
            list(APPEND selected_refs ${current_ref})
          endif()
        endforeach()
        set(refs ${selected_refs})
      endif()
    endif()

    popd()    

    set(result)
    foreach(ref ${refs})
      map_tryget(${ref} hash)
      ans(hash)
      set(immutable_uri "${remote_uri}?rev=${hash}")
      if(return_package_handle)
        set(package_handle)
        assign(!package_handle.uri = immutable_uri)
        assign(!package_handle.scm_descriptor.scm = 'hg')
        assign(!ref.uri = remote_uri)
        assign(!package_handle.scm_descriptor.ref =  ref)
        assign(!package_handle.query_uri = uri.uri)

        list(APPEND result ${package_handle})
      else()
        list(APPEND result ${immutable_uri})
      endif()

    endforeach()
    return_ref(result)
  endfunction() 




## package_source_resolve_hg
##
## resolves a uri package to a immutable unqiue uri 
##
  function(package_source_resolve_hg uri)
    set(args ${ARGN})
    uri("${uri}")
    ans(uri)

    package_source_query_hg("${uri}" --package-handle)
    ans(package_handle)

    list(LENGTH package_handle count)
    if(NOT "${count}" EQUAL 1)
      error("could not uniquely resolve {uri.uri}" uri package_handle)
      return()
    endif()


    assign(remote_uri = package_handle.scm_descriptor.ref.uri)
    assign(hash = package_handle.scm_descriptor.ref.hash)


    hg_cached_clone("${remote_uri}" --ref "${hash}" --read package.cmake)
    ans(package_descriptor_content)

    json_deserialize("${package_descriptor_content}")
    ans(package_descriptor)

    assign(default_id = uri.file_name)
    map_defaults("${package_descriptor}" "{
      id:$default_id,
      version:'0.0.0'
    }")
    ans(package_descriptor)
    map_set(${package_handle} package_descriptor "${package_descriptor}")

    return_ref(package_handle)

  endfunction()





## `()-> <package source>`
##
## creates a host package source which provides information
## on the host system
function(host_package_source)
  map_new()
  ans(this)
  map_set(${this} source_name "host")
  map_set(${this} query package_source_query_host)
  map_set(${this} resolve package_source_resolve_host)
  map_set(${this} pull package_source_pull_host)
  map_set(${this} rate_uri package_source_rate_uri_host)
  return(${this})
endfunction()






## `(<uri> [<target dir>])-> <package handle>`
##
## pulls the specified host package into the target_dir
## this functions currently just creates a directory with nothing in it
function(package_source_pull_host uri)
  set(args ${ARGN})
  uri_coerce(uri)
  package_source_resolve_host("${uri}")
  ans(package_handle)

  list_pop_front(args)
  ans(target_dir)
  if(NOT package_handle)
    return()
  endif()

  path_qualify(target_dir)

  mkdir("${target_dir}")

  assign(package_handle.content_dir = target_dir)

  return_ref(package_handle)
endfunction()





  function(package_source_query_host uri)
    set(args ${ARGN})

    list_extract_flag(args --package-handle)
    ans(return_package_handle)

    uri_coerce(uri)

    ## uri needs to have the host scheme
    uri_check_scheme("${uri}" host)
    ans(ok)

    map_tryget(${uri} scheme_specific_part)
    ans(hostname)

    if(NOT ok)
      return()
    endif()

    if(hostname AND NOT "${hostname}" STREQUAL "localhost")
      return()
    endif()


    cmake_environment()
    ans(environment)

    set(result "host:localhost")
    if(return_package_handle)
      set(package_handle)
      assign(!package_handle.uri = result)
      assign(!package_handle.query_uri = uri.uri)
      assign(!package_handle.environment_descriptor = environment)
      set(result "${package_handle}")
    endif()

    return_ref(result)
  endfunction()






  function(package_source_rate_uri_host uri)
    uri_coerce(uri)
    uri_check_scheme("${uri}" host)
    ans(ok)
    if(NOT ok)
      return(0)
    endif()
    return(999)
  endfunction()





## `(<uri>)-><package handle>`
## 
## tries to find the package identified by the uri 
function(package_source_resolve_host uri)
  uri_coerce(uri)
  package_source_query_host("${uri}" --package-handle)
  ans(package_handle)


  list(LENGTH package_handle count)

  if(NOT "${count}" EQUAL 1)
    error("could not unqiuely resolve {uri.uri} to a single package uri (got {count})")
    return()
  endif()

  map_tryget(${package_handle} environment_descriptor)
  ans(environment_descriptor)

  map_new()
  ans(package_descriptor)

  map_set(${package_descriptor} environment_descriptor ${environment_descriptor})
  map_set(${package_handle} package_descriptor ${package_descriptor})


  return_ref(package_handle)
endfunction()





function(managed_package_source source_name directory)
  path_qualify(directory)
  obj("{
    source_name:$source_name,
    directory:$directory,
    pull:'package_source_pull_managed',
    push:'package_source_push_managed',
    query:'package_source_query_managed',
    resolve:'package_source_resolve_managed',
    delete:'package_source_delete_managed'
  }")
  return_ans()
endfunction()







  ## package_handle_hash(<~package handle>) -> <string>
  ## creates a hash for an installed package the hash should be unique enough and readable enough
  function(package_handle_hash package_handle)
    package_handle("${package_handle}")
    ans(package_handle)

    assign(id = package_handle.package_descriptor.id)
    assign(version = package_handle.package_descriptor.version)

    set(hash "${id}_${version}")
    string(REPLACE "." "_" hash "${hash}")
    string(REPLACE "/" "_" hash "${hash}")
    return_ref(hash)
  endfunction()





function(package_source_delete_managed uri)
  uri_coerce(uri)

  package_source_resolve_managed("${uri}")
  ans(package_handle)


  if(NOT package_handle)
    return(false)
  endif()

  assign(location = package_handle.managed_descriptor.managed_dir)
  if(NOT EXISTS "${location}")
    message(FATAL_ERROR "the package is known but its directory does not exist")
  endif()

  rm(-r "${location}")

  return(true)
endfunction()





  ## package_source_pull_managed(<~uri>) -> <package handle>
  ## --reference returns the package with the content still pointing to the original content dir
  function(package_source_pull_managed uri)
    set(args ${ARGN})

    uri_coerce(uri)

    package_source_resolve_managed("${uri}")
    ans(package_handle)
    if(NOT package_handle)
      return()
    endif()

    list_extract_flag(args --reference)
    ans(reference)


    ## if in reference mode copy package_handle content and set new content_dir
    if(NOT reference)
      list_pop_front(args)
      ans(target_dir)
      path_qualify(target_dir)
      
      map_tryget(${package_handle} content_dir)
      ans(source_dir)
      
      cp_dir("${source_dir}" "${target_dir}")
      map_set(${package_handle} content_dir "${target_dir}")
    endif()

    return_ref(package_handle)
  endfunction()







  ## package_source_push_managed(<package handle> ) -> <uri string>
  ##
  ## returns a valid uri if the package was pushed successfully 
  ## else returns null
  ##
  ## expects a this object to be defined which contains directory and source_name
  ## --reference flag indicates that the content will not be copied into the the package source 
  ##             the already existing package dir will be used 
  ## --content-dir <dir> flag indicates where the package content will reside
  ## --package-dir <dir> flag indicates parent dir of content of package
  ## --force     flag indicates that existing package should be overwritten
  function(package_source_push_managed)
    if("${ARGN}" MATCHES "(.*);=>;?(.*)")
        set(source_args "${CMAKE_MATCH_1}")
        set(args "${CMAKE_MATCH_2}")
    else()
        set(source_args ${ARGN})
        set(args)
    endif()
    list_pop_front(source_args)
    ans(source)

    list_extract_labelled_value(source_args --content-dir)
    ans(content_dir)

    list_extract_labelled_value(source_args --package-dir)
    ans(package_dir)

    list_extract_flag(args --force)
    ans(force)

    this_get(directory)

    list_pop_front(source_args)
    ans(uri)

    uri_coerce(uri)

    assign(package_handle = source.resolve(${uri}))

    if(NOT package_handle)
      error("could not resolve ${source_args} to a package handle")
      return()
    endif()

    package_handle_hash("${package_handle}")
    ans(hash)

    set(managed_dir "${directory}/${hash}")

    if(EXISTS "${managed_dir}" AND NOT force)
      error("package (${hash}) already exists ")
      return()
    endif()

    if(NOT content_dir)
      if(NOT package_dir)
        this_get(package_dir)
      endif()
      if(package_dir)
        assign(id = package_handle.package_descriptor.id)
        assign(version = package_handle.package_descriptor.version)
        

        path("${package_dir}/${id}")
        ans(content_dir)
        if(EXISTS "${content_dir}")
          path("${package_dir}/${id}@${version}")
          ans(content_dir)
          if(EXISTS "${content_dir}")
            path("${package_dir}/${hash}")
          endif()
        endif()
      else()
        set(content_dir "${managed_dir}/content")
      endif()
    else()
      path_qualify(content_dir)
    endif()

    assign(package_handle = source.pull("${uri}" ${source_args} "${content_dir}"))
    if(NOT package_handle)
      error("failed to pull {uri.uri} to {content_dir}")
      return()
    endif()
    assign(!package_handle.managed_descriptor.hash = hash)
    assign(!package_handle.managed_descriptor.managed_dir = managed_dir)
    assign(!package_handle.managed_descriptor.remote_source_name = source.source_name)
    assign(!package_handle.managed_descriptor.remote_uri = uri.uri)
    assign(!package_handle.working_dir = '${managed_dir}/workspace')

    qm_write("${managed_dir}/package_handle.qm" "${package_handle}")


    return_ref(package_handle)


  endfunction()









  ## package_source_query_managed(<~uri>) -> <uri string>
  ## 
  ## expects a this object to be defined which contains directory and source_name
  ## 
  function(package_source_query_managed uri)
    set(args ${ARGN})


    list_extract_flag(args --package-handle)
    ans(return_package_handle)

    this_get(directory)
    this_get(source_name)

    uri_coerce(uri)

    ### read all package handles (new objects)
    ### also set the query_uri field
    file(GLOB package_handle_files "${directory}/*/package_handle.qm")
    set(package_handles)

    ## this is slow and may be made faster
    foreach(package_handle_file ${package_handle_files})
      qm_read("${package_handle_file}")
      ans(package_handle)
      assign(package_handle.query_uri = uri.uri)
      list(APPEND package_handles ${package_handle})
    endforeach()


    ## filter package handles by query
    package_handle_filter(package_handles "${uri}")
    ans(filtered_handles)

    if(NOT return_package_handle)
      set(package_uris)
      foreach(package_handle ${filtered_handles})
        map_tryget(${package_handle} uri)
        ans(uri)
        list(APPEND package_uris ${uri})
      endforeach()
      return_ref(package_uris)
    else()
      return_ref(filtered_handles)
    endif() 


    return()
  endfunction()




  ## package_source_resolve_managed(<~uri>) -> <package_handle>
  ##
  ## expects a var called this exist which contains the properties 'directory' and 'source_name'
  ## 
  function(package_source_resolve_managed uri)
    uri_coerce(uri)


    ## query for package uri
    package_source_query_managed("${uri}" --package-handle)
    ans(package_handle)


    list(LENGTH package_handle count)
    if(NOT "${count}" EQUAL 1)
      return()
    endif()

    return_ref(package_handle)


    return()

  endfunction()





  function(metadata_package_source source_name)
    map_new()
    ans(this)
    map_set(${this} source_name ${source_name})
    map_set(${this} query package_source_query_metadata)
    map_set(${this} resolve package_source_resolve_metadata)
    map_set(${this} pull package_source_pull_metadata)
    map_set(${this} push package_source_push_metadata)
    map_set(${this} add_package_descriptor package_source_metadata_add_descriptor)
    map_new()
    ans(metadata)
    map_set(${this} metadata ${metadata})
    return_ref(this)
  endfunction()






  function(package_source_metadata_add_descriptor package_descriptor)
    obj("${package_descriptor}")
    ans(package_descriptor)

    if(NOT package_descriptor)
      message(FATAL_ERROR "package_source_metadata_add_descriptor: no valid package_descriptor")
    endif()

    map_import_properties(${package_descriptor} id version make_current)
    if(NOT version)
      set(version "0.0.0")
    endif()
    map_remove("${package_descriptor}" make_current)

    this_get(metadata)

    assign(id = package_descriptor.id)
    if(NOT id)
      message(FATAL_ERROR "no valid package id")
    endif()
    

    map_clone_deep("${package_descriptor}")
    ans(new_package_descriptor)
    map_tryget(${metadata} "${id}@${version}")
    ans(package_descriptor)
    if(package_descriptor)
      map_clear(${package_descriptor})
      map_copy_shallow(${package_descriptor} ${new_package_descriptor})
      return(${package_descriptor})
    endif()
    set(package_descriptor ${new_package_descriptor})


    map_append(${metadata} "${id}@*" ${package_descriptor})
    map_append(${metadata} "*" ${package_descriptor})

    map_has(${metadata} ${id})
    ans(has_current)
    if(make_current OR NOT has_current)
      map_set(${metadata} ${id} ${package_descriptor})
    endif()  
    map_set(${metadata} "${id}@${version}" ${package_descriptor})
    
    return_ref(package_descriptor)
  endfunction()





  function(package_source_pull_metadata uri)
    set(args ${ARGN})
    list_pop_front(args)
    ans(content_dir)
    path_qualify(content_dir)

    package_source_resolve_metadata("${uri}")
    ans(package_handle)

    if(NOT package_handle)
      return()
    endif()

    mkdir("${content_dir}")
    map_set(${package_handle} content_dir "${content_dir}")
    return_ref(package_handle)
  endfunction()






  function(package_source_push_metadata)
    if("${ARGN}" MATCHES "(.*);=>;?(.*)")
        set(source_args "${CMAKE_MATCH_1}")
        set(args "${CMAKE_MATCH_2}")
    else()
        set(source_args ${ARGN})
        set(args)
    endif()
    list_pop_front(source_args)
    ans(source)

    list_pop_front(source_args)
    ans(uri)

    uri_coerce(uri)

    assign(package_handle = source.resolve(${uri}))
    if(NOT package_handle)
      error("could not resolve {uri.uri} to a package handle")
      return()
    endif()

    map_tryget(${package_handle} package_descriptor)
    ans(package_descriptor)

    package_source_metadata_add_descriptor(${package_descriptor})
    return_ref(package_handle)
  endfunction() 






  function(package_source_query_metadata input_uri)
    set(args ${ARGN})
    uri_coerce(input_uri)
    list_extract_flag(args --package-handle)
    ans(return_package_handle)

    this_get(metadata)
    this_get(source_name)

    uri_check_scheme(${input_uri} "${source_name}?")
    ans(scheme_ok)
    if(NOT scheme_ok)
      return()
    endif()


    map_tryget(${input_uri} normalized_segments)
    ans(ids)
    if(NOT ids)
      return()
    endif()

    map_tryget(${metadata} ${ids})
    ans(package_descriptors)
    
    set(result)
    foreach(package_descriptor ${package_descriptors})
      map_import_properties(${package_descriptor} id version)
      map_tryget(${metadata} ${id})
      ans(current)
      if("${current}" STREQUAL "${package_descriptor}")
        set(uri "${source_name}:${id}")
      else()
        set(uri "${source_name}:${id}@${version}")
      endif()
      if(return_package_handle)
        map_tryget(${input_uri} uri)
        ans(query_uri)
        map_capture_new(uri query_uri package_descriptor)
        ans_append(result)
      else()
        list(APPEND result "${uri}")
      endif()
    endforeach()

    return_ref(result)



  endfunction()






  function(package_source_resolve_metadata uri)
    uri_coerce(uri)
    package_source_query_metadata("${uri}" --package-handle)
    ans(handles)

    list(LENGTH handles count)
    if(NOT "${count}" EQUAL 1)
      error("could not uniquely resolve {uri.uri} (got {count}) packages")
      return()
    endif()    
    return_ref(handles)
  endfunction()





## 
##
## package source to be used for testing purposes 
## allows easy definition of packages and dependency relationsships
## to define a package write "<package id>[@<verion>][ <package descriptor obj>]"
## e.g. "A" "A@3.2.1" "A@3.4.1 {cmakepp:{hooks:{on_ready:'[]()message(ready)'}}}"
## to define a relationship write "<package id> => <package id>"
function(mock_package_source name)
  metadata_package_source("${name}")
  ans(package_source)
  map_new()
  ans(graph)
  foreach(arg ${ARGN})
    if("${arg}" MATCHES "(.+)=>(.+)")
      set(id "${CMAKE_MATCH_1}")
      set(dep "${CMAKE_MATCH_2}")
      map_tryget(${graph} "${id}")
      ans(pd)
      if(NOT pd)
        message(FATAL_ERROR "no package found called ${id}")
      endif()

      map_new()
      ans(ph)
      map_set("${ph}" package_descriptor "${pd}") 
      package_handle_update_dependencies("${ph}" "${dep}")
    else()
      if("${arg}" MATCHES "^([^ ]+) (.*)$")
        set(id "${CMAKE_MATCH_1}")
        set(config "${CMAKE_MATCH_2}")
      else()
        set(id "${arg}")
        set(config "")
      endif()

      set(unique_id "${id}")
      if("${id}" MATCHES "(.+)@(.+)")
        set(id "${CMAKE_MATCH_1}")
        set(version "${CMAKE_MATCH_2}")
      else()
        set(version "0.0.0")
      endif()
      set(asd ${arg})
      map_capture_new(id version)
      ans(pd)
      if(config)
        obj("${config}")
        ans(config)
        map_copy_shallow(${pd} ${config})
      endif()
      map_set(${graph} "${unique_id}" "${pd}")
    endif()


  endforeach()
  map_values(${graph})
  ans(pds)
  foreach(pd ${pds})
    assign(success = package_source.add_package_descriptor("${pd}"))
  endforeach()
  return_ref(package_source)
endfunction()




## `()-><package source>`
##
## returns the specified package source
## valid package soruces are returned
## valid package source types are created and returned
function(package_source source)
  is_map("${source}")
  ans(ismap)
  if(ismap)
    return_ref(source)
  endif()

  if(NOT COMMAND "${source}_package_source")
    return()
  endif()
  eval("${source}_package_source(${ARGN})")
  return_ans()
endfunction()





## `(<admissable_uri> [--cache <map>])-> { <<package uri>:<package handle>>...}` 
##
##
function(package_source_query_resolve package_source admissable_uri)
  set(args ${ARGN})    

  ## get cache and if none exists create new
  list_extract_labelled_value(args --cache)
  ans(cache)
  if(NOT cache)
    map_new()
    ans(cache)
  endif()

  #message("uri ${admissable_uri}")

  set(resolved_handles)
  map_has("${cache}" "${admissable_uri}")
  ans(hit)
  if(hit)
    map_tryget("${cache}" "${admissable_uri}")
    ans(resolved_handles)
    #message("hit for ${admissable_uri} :${resolved_handles}")

  else()
    if(NOT package_source)
      message(FATAL_ERROR "no package source specified!")
    endif()
    call(package_source.query("${admissable_uri}"))
    ans(dependable_uris)

    ## resolve loop
    foreach(dependable_uri ${dependable_uris})
      package_source_resolve("${package_source}" "${dependable_uri}" --cache ${cache})
      ans(resolved_handle)
      if(resolved_handle)
        map_append_unique("${cache}" "${admissable_uri}" ${resolved_handle})
        list(APPEND resolved_handles ${resolved_handle})
      endif()
    endforeach()
  endif()

  map_new()
  ans(result)
  foreach(resolved_handle ${resolved_handles})
    map_tryget(${resolved_handle} uri)
    ans(resolved_uri)
    map_set(${result} ${resolved_uri} ${resolved_handle})
  endforeach()
  return_ref(result)
endfunction()





## `(<admissable uri>... [--cache <map>])-> { <<admissable uri>:<package handle>>... }`
##
##
function(package_source_query_resolve_all package_source)
  set(args ${ARGN})
  list_extract_labelled_value(args --cache)
  ans(cache)
  if(NOT cache)
    map_new()
    ans(cache)
  endif()
  set(admissable_uris ${args})
  
  map_new()
  ans(result)


  ## loop througgh all admissable uris
  foreach(admissable_uri ${admissable_uris})
    package_source_query_resolve("${package_source}" "${admissable_uri}" --cache ${cache})
    ans(resolved)
    map_set(${result} ${admissable_uri} ${resolved})
  endforeach()

  return_ref(result)
endfunction()







## `(<package source> <volatile uri> [--cache:<map>])-><package handle>?`
##
## resolves a package handle using the specified cache
function(package_source_resolve package_source uri)
  set(args ${ARGN})
  list_extract_labelled_value(args --cache)
  ans(cache)
  if(NOT cache)
    map_new()
    ans(cache)
  endif()

  map_has(${cache} "${uri}")
  ans(hit)
  if(hit)
    map_tryget(${cache} ${uri})
    ans(resolved_handle)
    list(LENGTH resolved_handle count)
    if(NOT ${count} EQUAL 1)
      return()
    endif()
  else()
    call(package_source.resolve("${uri}"))
    ans(resolved_handle)
    map_set(${cache} ${uri} ${resolved_handle})
    if(NOT resolved_handle)
      return()
    endif()
    map_tryget(${resolved_handle} uri)
    ans(dependable_uri)
    map_set(${cache} ${dependable_uri} ${resolved_handle})
  endif()

  return_ref(resolved_handle)
endfunction()




function(package_source_transfer)
  if("${ARGN}" MATCHES "(.*)=>(.*)")
    set(source_args ${CMAKE_MATCH_1})
    set(sink_args ${CMAKE_MATCH_2})
  else()
    message(FATAL_ERROR "invalid arguments. expcted <source> <source args> => <sink> <sink args>")
  endif()
  list_pop_front(source_args)
  ans(source)

  list_pop_front(sink_args)
  ans(sink)

  assign(package_handle = sink.push(${source} ${source_args} => ${sink_args}))
    
  return_ref(package_handle)
endfunction()





## package_source_pull(<~uri> <?target_dir:<path>>) -> <package handle>
##
## pulls the content of package specified by uri into the target_dir 
## if the package_descriptor contains a content property it will interpreted
## as a glob/ignore expression list when copy files (see cp_content(...)) 
##
## --reference flag indicates that nothing is to be copied but the source 
##             directory will be used as content dir 
##
## 
function(package_source_pull_path uri)
    set(args ${ARGN})

    uri_coerce(uri)

    ## get package descriptor for requested uri
    package_source_resolve_path("${uri}")
    ans(package_handle)

    if(NOT package_handle)
        error("could not resolve {uri.uri} to a unique package")
      return()
    endif()


    list_extract_flag(args --reference)
    ans(reference)

    if(NOT reference)
        ## get and qualify target path
        list_pop_front(args)
        ans(target_dir)
        path_qualify(target_dir)


        assign(source_dir = package_handle.directory_descriptor.path)

        ## copy content to target dir
        assign(content_globbing_expression = package_handle.package_descriptor.content)

        cp_content("${source_dir}" "${target_dir}" ${content_globbing_expression})

        ## replace content_dir with the new target path and return  package_handle
        map_set("${package_handle}" content_dir "${target_dir}")
    else()
        assign(package_handle.content_dir = package_handle.directory_descriptor.path)
    endif()

    return_ref(package_handle)
endfunction()




## (<installed package> <~uri> [--reference] [--consume] <package_content_copy_args:<args...>?>)
##
function(package_source_push_path)
    if("${ARGN}" MATCHES "(.*);=>;?(.*)")
        set(source_args "${CMAKE_MATCH_1}")
        set(args "${CMAKE_MATCH_2}")
    else()
        set(source_args ${ARGN})
        set(args)
    endif()
    list_pop_front(source_args)
    ans(source)
        

    ## get target dir
    list_pop_front(args)
    ans(target_dir)
    if(NOT target_dir)
        pwd()
        ans(target_dir)        
    endif()

    path_qualify(target_dir)

    assign(package_handle = source.pull(${source_args} "${target_dir}"))


    if(NOT package_handle)
        error("could not pull `${source_args}` ")
        return()
    endif()

    if(NOT EXISTS "${target_dir}/package.cmake")
        assign(package_descriptor = package_handle.package_descriptor)
        json_write("${target_dir}/package.cmake" "${package_descriptor}")
    endif()

    return_ref(package_handle)
endfunction()




## package_source_query_path(<uri> <?target_path>)
function(package_source_query_path uri)
  set(args ${ARGN})

  uri_coerce(uri)

  list_extract_flag(args --package-handle)
  ans(return_package_handle)



  ## check that uri is local
  map_tryget("${uri}" "normalized_host")
  ans(host)

  if(NOT "${host}" STREQUAL "localhost")
    return()
  endif()   

  uri_check_scheme("${uri}" "file?")
  ans(scheme_ok)
  if(NOT scheme_ok)
    error("path package query only accepts file and <none> as a scheme")
    return()
  endif()

  map_import_properties(${uri} query)
  
 if(NOT "_${query}" MATCHES "(^_$)|(_hash=[0-9a-zA-Z]+)")
    error("path package source only accepts a hash query in the uri.")
    return()
  endif()

  ## get localpath from uri and check that it is a dir and cotnains a package_descriptor
  uri_to_localpath("${uri}")
  ans(path)

  path_qualify(path)

  if(NOT IS_DIRECTORY "${path}")
    return()
  endif()

  ## old style package descriptor
  json_read("${path}/package.cmake")
  ans(package_descriptor)
  if(NOT package_descriptor)
    ## tries to open the package descriptor
    ## in any other format
    fopen_data("${path}/package")
    ans(package_descriptor)
  endif()
  


  ## compute hash
  set(content)


  
  assign(default_id = uri.last_segment)
  map_defaults("${package_descriptor}" "{id:$default_id,version:'0.0.0'}")
  ans(package_descriptor)
  assign(content = package_descriptor.content)

  if(content)
    pushd("${path}")
      checksum_glob_ignore(${content})
      ans(hash)
    popd()
  else()
    checksum_dir("${path}")
    ans(hash)
  endif()
  assign(expected_hash = uri.params.hash)

  if(expected_hash AND NOT "${hash}" STREQUAL "${expected_hash}")
    error("hashes did not match for ${path}")
    return()
  endif()
  ## create the valid result uri (file:///e/t/c)
  uri("${path}?hash=${hash}")
  ans(result)

  ## convert uri to string
  uri_format("${result}")
  ans(result)

  if(return_package_handle)
    set(package_handle)
    assign(!package_handle.uri = result)
    assign(!package_handle.query_uri = uri.uri)
    assign(!package_handle.package_descriptor = package_descriptor)
    assign(!package_handle.directory_descriptor.hash = hash)
    assign(!package_handle.directory_descriptor.path = path)
    assign(!package_handle.directory_descriptor.pwd = pwd())

    set(result ${package_handle})
  endif()

return_ref(result)
endfunction()




## returns a pacakge descriptor if the uri identifies a unique package
function(package_source_resolve_path uri)
    uri_coerce(uri)


    package_source_query_path("${uri}" --package-handle)
    ans(package_handle)

    list(LENGTH package_handle count)
    if(NOT "${count}" EQUAL 1)
        error("could not find a unique immutbale uri for {uri.uri}")
        return()
    endif()


    return_ref(package_handle)

endfunction()





## `()`
##
## returns full rating if 
## dir/package.cmake exists 
## and a very high rating for a directory 
## else it returns 0
function(package_soure_rate_uri_path uri)
  uri_coerce(uri)
  uri_to_localpath("${uri}")
  ans(localpath)
  if(EXISTS "${localpath}/package.cmake")
    return(999)
  endif()
  if(IS_DIRECTORY "${localpath}")
    return(998)
  endif()
  path_qualify(localpath)
  if(EXISTS "${localpath}")
    return(500)
  endif()
  return(0)
endfunction()




##
##
##
function(path_package_source)
  obj("{
    source_name:'file',
    pull:'package_source_pull_path',
    push:'package_source_push_path',
    query:'package_source_query_path',
    resolve:'package_source_resolve_path',
    rate_uri:'package_soure_rate_uri_path'
  }")
  return_ans()
endfunction()




# <package_descriptor>
# {
#    content:<defaults to this file>,
#    cmakepp:{
#       export:<defaults to this file>
#       on_install: <...?>
#       on_load: <any function in this file>
#       on_uninstall: <any function in this file>
#    }
# }
# </package_descriptor>

function(package_source_query_recipe)
  

 

endfunction()






  function(package_source_pull_svn uri)
    set(args ${ARGN})

    package_source_query_svn("${uri}")
    ans(valid_uri_string)

    list(LENGTH valid_uri_string uri_count)
    if(NOT uri_count EQUAL 1)
      return()
    endif()

    uri("${valid_uri_string}")
    ans(uri)


    uri_format("${uri}" --no-query --remove-scheme svnscm)
    ans(remote_uri)

    list_pop_front(args)
    ans(target_dir)
    path_qualify(target_dir)

    ## branch / tag / trunk / revision
    assign(svn_revision = uri.params.revision)
    assign(svn_branch = uri.params.branch)
    assign(svn_tag = uri.params.tag)
    if(NOT svn_revision STREQUAL "")
      set(svn_revision --revision "${svn_revision}")
    endif() 

    if(NOT svn_branch STREQUAL "")
      set(svn_branch --branch "${svn_branch}")
    endif() 

    if(NOT svn_tag STREQUAL "")
      set(svn_tag --tag "${svn_tag}")
    endif() 

    svn_cached_checkout("${remote_uri}" "${target_dir}" ${revision} ${branch} ${tag})
    ans(success)

    if(NOT success)
      return()
    endif()


    ## package_descriptor
    package_handle("${target_dir}")
    ans(package_handle)

    map_tryget("${package_handle}" package_descriptor)
    ans(package_descriptor)


    ## response
    map_new()
    ans(result)
    map_set("${result}" package_descriptor "${package_descriptor}")
    map_set("${result}" uri "${valid_uri_string}")
    map_set("${result}" content_dir "${target_dir}")
    return(${result})

  endfunction()






##
##
##
function(package_source_query_svn uri)
  set(args ${ARGN})
  list_extract_flag(args --package-handle)
  ans(return_package_handle)

  uri_coerce(uri)  

  svn_uri_analyze("${uri}")
  ans(svn_uri)

  svn_uri_format_ref("${svn_uri}")
  ans(ref_uri)

  svn_remote_exists("${ref_uri}")
  ans(remote_exists)

  if(NOT remote_exists)
    return()
  endif()

  svn_uri_format_package_uri("${svn_uri}")
  ans(package_uri)

  set(package_uri "svnscm+${package_uri}")

  if(return_package_handle)
    map_new()
    ans(package_handle)
    map_set(${package_handle} uri ${package_uri})
    assign(package_handle.query_uri = uri.uri)

    return(${package_handle})
  endif()

  return(${package_uri})

endfunction()





  function(package_source_resolve_svn uri)
    package_source_query_svn("${uri}")
    ans(valid_uri_string)
    list(LENGTH valid_uri_string uri_count)

    if(NOT uri_count EQUAL 1)
      return()
    endif()



    svn_uri_analyze("${valid_uri_string}")
    ans(svn_uri)

    map_import_properties(${svn_uri} base_uri ref_type ref revision)

    string(REGEX REPLACE "^svnscm\\+" "" base_uri "${base_uri}")
    if(NOT revision)
      set(revision HEAD)
    endif()


    if("${ref_type}" STREQUAL "branch")
      set(ref_type branches)
    elseif("${ref_type}" STREQUAL "tag")
      set(ref_type tags)
    endif()
    set(checkout_uri "${base_uri}/${ref_type}/${ref}/package.cmake@${revision}")
    
    fwrite_temp("")
    ans(tmp)
    rm(${tmp})
    svn(export "${checkout_uri}" "${tmp}" --exit-code)
    ans(error)

    if(NOT error)
      package_handle("${tmp}")
      ans(package_handle)

      map_tryget("${package_handle}" package_descriptor)
      ans(package_descriptor)
      rm(tmp)
    endif()

    string(REGEX MATCH "[^/]+$" default_id "${base_uri}")

    map_defaults("${package_descriptor}" "{
      id:$default_id,
      version:'0.0.0'
    }")
    ans(package_descriptor)
    ## response
    map_new()
    ans(package_handle)

    map_set(${package_handle} package_descriptor "${package_descriptor}")
    map_set(${package_handle} uri "${valid_uri_string}")

    return_ref(package_handle)
  endfunction()





  function(svn_package_source)
    obj("{
      source_name:'svnscm',
      pull:'package_source_pull_svn',
      query:'package_source_query_svn',
      resolve:'package_source_resolve_svn'
    }")
    return_ans()
  endfunction()






  function(package_source_pull_webarchive uri)
    set(args ${ARGN})

    uri_coerce(uri)

    list_extract_flag_name(args --refresh)
    ans(refresh)

    list_pop_front(args)
    ans(target_dir)

    path_qualify(target_dir)

    package_source_resolve_webarchive("${uri}")
    ans(package_handle)
    if(NOT package_handle)
        error("could not resolve webarchive {uri.uri}" --aftereffect)
        return()
    endif()
    assign(archive_path = package_handle.archive_descriptor.path)

    package_source_pull_archive("${archive_path}" ${target_dir})
    ans(archive_package_handle)
    if(NOT archive_package_handle)
        error("could not pull downloaded archive" --aftereffect)
        return()
    endif()

    map_set(${package_handle} content_dir ${target_dir})
    

    return_ref(package_handle)

  endfunction()






## package_source_query_webarchive(<~uri> [--package-handle] [--refresh] <args...>) -> <package uri...>
##
## if uri identifies a package the <package uri> is returned - else nothing is returned  
##
## queries the specified uri for a remote <archive> uses `download_cached` to
## download it. (else it would have to be downloaded multiple times)
##
##   
function(package_source_query_webarchive uri)
  set(args ${ARGN})


  list_extract_flag(args --package-handle)
  ans(return_package_handle)

  ## parse and format uri
  uri_coerce(uri)

  uri_check_scheme("${uri}" http? https?)
  ans(scheme_ok)

  if(NOT scheme_ok)
    return()
  endif()

  assign(uri_string = uri.uri)
  ## remove the last instance of the hash query - if it exists
  ## an edge case were this woudl fail is when another hash is meant
  ## a solution then would be to prepend the hash with a magic string 
  string(REGEX REPLACE "hash=[0-9A-Fa-f]+$" "" uri_string "${uri_string}")

  ## use download cached to download a package (pass along vars like --refresh)
  download_cached("${uri_string}" --readonly ${args})
  ans(path)

  if(NOT EXISTS "${path}")
    error("could not download ${uri_string}")
    return()
  endif()

  assign(expected_hash = uri.params.hash)

  package_source_query_archive("${path}?hash=${expected_hash}" --package-handle)
  ans(package_handle)

  if(NOT package_handle)
    error("specified file uri {uri.uri} is not a supported archive or hash mismatch")
    return()
  endif()

  assign(hash = package_handle.archive_descriptor.hash)


  uri_format("${uri}" "{hash:$hash}")
  ans(package_uri)

  if(NOT return_package_handle)
    return_ref(package_uri)
  endif()

  assign(package_handle.uri = package_uri )
  assign(package_handle.query_uri = uri.uri )
  assign(package_handle.resource_uri = uri_string)

  return_ref(package_handle)

endfunction()






  function(package_source_rate_uri_webarchive uri)
    uri_coerce(uri)

    uri_check_scheme(${uri} "http?" "https?")
    ans(scheme_ok)
    if(NOT scheme_ok)
      return(0)
    endif()



    map_tryget(${uri} file)
    ans(file)

    if("${file}" MATCHES "(tar\\.gz$)|(\\.gz$)")
      return(1000)
    endif()

    return(50)
  endfunction()




## package_source_resolve_webarchive([--refresh])-><package handle>

  function(package_source_resolve_webarchive uri)
    set(args ${ARGN})
    
    uri("${uri}")
    ans(uri)

    package_source_query_webarchive("${uri}" ${args} --package-handle)
    ans(package_handle)

    list(LENGTH package_handle count)
    if(NOT count EQUAL 1)
      error("could not resolve {uri.uri} matches {count} packages - needs to be unqiue" --aftereffect)
      return()
    endif()

    assign(resource_uri = package_handle.resource_uri)

    download_cached("${resource_uri}" --readonly)
    ans(cached_archive_path)

   
    if(NOT cached_archive_path)
        error("could not download {resource_uri}" --aftereffect)
        return()
    endif()
    package_source_resolve_archive("${cached_archive_path}")
    ans(archive_package_handle)
    if(NOT archive_package_handle)
        error("{uri.uri} is not a supported archive file ")
        return()
    endif()


    map_remove(${package_handle} content_dir)
    assign(package_handle.package_descriptor = archive_package_handle.package_descriptor)
    assign(package_handle.archive_descriptor = archive_package_handle.archive_descriptor)

    return_ref(package_handle)

  endfunction()










  function(webarchive_package_source)
    obj("{
      source_name:'webarchive',
      pull:'package_source_pull_webarchive',
      query:'package_source_query_webarchive',
      resolve:'package_source_resolve_webarchive',
      rate_uri:'package_source_rate_uri_webarchive'
    }")
    return_ans()
  endfunction()






## `(<project handle> <action...>)-><dependency changeset>`
##
## changes the dependencies of the specified project handle
## expects the project_descriptor to contain a valid package source
## returns the dependency changeset 
## **sideffects**
## * adds new '<dependency configuration>' `project_handle.project_descriptor.installation_queue`
## **events**
## * `project_on_dependency_configuration_changed(<project handle> <changeset>)` is called if dpendencies need to be changed
function(project_change_dependencies project_handle)
  set(args ${ARGN})

  map_tryget(${project_handle} project_descriptor)
  ans(project_descriptor)

  map_import_properties(${project_descriptor} 
    package_source
    package_cache
    )
  ## check for package source
  if(NOT package_source)
 #   message(FATAL_ERROR "no package source set up in project handle")
  endif()   

  ## get previous_configuration
  map_peek_back(${project_descriptor} installation_queue)
  ans(previous_configuration)

  if(NOT previous_configuration)
    map_new()
    ans(previous_configuration)
  endif()

  ## 
  package_dependency_configuration_update(
    "${package_source}"
    "${project_handle}"
    ${args}
    --cache ${package_cache}
    )
  ans(configuration)

  ## invalid configuration
  if(NOT configuration)
    return()
  endif()

  ## compute changeset  and return
  package_dependency_configuration_changeset(
    ${previous_configuration} 
    ${configuration}
  )
  ans(changeset)

  map_isempty(${changeset})
  ans(is_empty)
  if(is_empty)
    return_ref(changeset)
  endif()

  ## add the changeset to the installation queue
  map_append(${project_descriptor} installation_queue ${configuration})

  ## emit event
  event_emit(project_on_dependency_configuration_changed ${project_handle} ${changeset})

  return_ref(changeset)
endfunction()





## `(<project package> <package handle>)-><void>` 
##
## updates all dependencies starting at package
## **sideffects**
## * 
## **events**
## * project_on_package_all_dependencies_materialized(<project handle> <package handle>)
## * project_on_package_and_all_dependencies_materialized(<project handle> <package handle>)
function(project_package_ready_state_update project package)

  function(__dodfs_update_recurse current)
    ## recursion anchor: current is already visted or still being visited
    map_tryget(${context} ${current})
    ans(status)
    if(status)
      return()
    endif()
    map_set(${context} ${current} visiting)

    map_get_map(${current} dependency_descriptor)
    ans(dependency_descriptor)
          
    ## check if all dependencies of package are materialized
    package_handle_is_ready(${current})
    ans(is_ready)

    map_tryget(${dependency_descriptor} is_ready)
    ans(was_ready)


    if(is_ready AND NOT was_ready)
      event_emit(project_on_package_ready ${project} ${current})
    elseif(NOT is_ready AND was_ready)
      event_emit(project_on_package_unready ${project} ${current})
    else()
      ## no change
      map_set(${context} ${current} visited)
      return()
    endif()

    ## update dependency descriptor
    map_set(${dependency_descriptor} is_ready ${is_ready})

    ## visit each dependee to check if their ready state changed
    map_tryget(${current} dependees)
    map_flatten(${__ans})
    map_flatten(${__ans})
    ans(dependees)

    foreach(dependee ${dependees})
      __dodfs_update_recurse(${dependee})
    endforeach()

    map_set(${context} ${current} visited)
    return()
  endfunction()

  map_new()
  ans(context)
  __dodfs_update_recurse(${package})
  return()
endfunction()

## register event handles to automatically call 
## update ready state function
function(__project_ready_state_register_listeners)
  event_addhandler(project_on_package_dematerialized project_package_ready_state_update)
  event_addhandler(project_on_package_materialized project_package_ready_state_update)
  event_addhandler(project_on_dependency_configuration_changed "[](project) project_package_ready_state_update({{project}} {{project}})")
endfunction()
task_enqueue(__project_ready_state_register_listeners)




##
##
##
function(cmake_export_handler project_handle package_handle)

  ## load the exports and includes them once
  assign(content_dir = package_handle.content_dir)
  assign(export = package_handle.package_descriptor.cmake.export)
  if(IS_DIRECTORY "${content_dir}")
    pushd("${content_dir}")
      glob_ignore("${export}")
      ans(paths)
    popd()
    foreach(path ${paths})
      include_once("${path}")
    endforeach()
  endif()
endfunction()





  function(package_cmake_module_content package module)
    map_import_properties(${package} content_dir)

    map_import_properties(${module} 
      add_as_subdirectory
      include_dirs
     )
    pushd(${content_dir})
    paths(${include_dirs})
    ans(include_dirs)
    if(NOT include_dirs)
      set(include_dirs ${content_dir})
    endif()
    popd()
    assign(module_name = package.package_descriptor.id)
   # string(TOUPPER "${module_name}" module_name)
    format("##
set({module_name}_DIR \"{content_dir}\")
set({module_name}_INCLUDE_DIRECTORIES ${include_dirs})
set({module_name}_FOUND \"{content_dir}\")

")
    ans(result)
    if(add_as_subdirectory)
      set(result "${result}add_subdirectory(\${${module_name}_DIR})" )
    endif()
    return_ref(result)
  endfunction()





  macro(project_cmake_constants)
    set(project_cmake_module_dir "cmake")
    set(project_cmake_module_include_dir "include")
  endmacro()





function(project_cmake_export_config project package)
  assign(install = package.package_descriptor.cmake.install)
  if(NOT install)
    return()
  endif()


  map_tryget(${project} content_dir)
  ans(project_dir)
  map_tryget(${project} project_descriptor)
  ans(project_descriptor)
  map_tryget(${project_descriptor} config_dir)
  ans(config_dir)

  print_vars(config_dir project_dir install)

endfunction()









  function(project_cmake_export_module project package)
    assign(module = package.package_descriptor.cmake.module)
    if(NOT module)
      return()
    endif()

    assign(module_name = package.package_descriptor.id)
    if(NOT module_name)
      error("project_cmake_export_module: package requires a id unique to project.")
      return()
    endif()

    set(module_file_name "Find${module_name}.cmake")

    project_cmake_constants()

    map_tryget(${package} content_dir)
    ans(package_dir)
    map_tryget(${project} content_dir)
    ans(project_dir)

    map_get_map(${project} cmake_descriptor)
    ans(cmake_descriptor)

    map_get_default(${cmake_descriptor} module_dir "${project_cmake_module_dir}")
    ans(module_dir)


    path_qualify_from("${project_dir}" "${module_dir}")
    ans(module_dir)

    print_vars(package_dir module_dir project_dir module_name)

    path_qualify_from("${module_dir}" "${module_file_name}")
    ans(module_file_path)


    if(NOT EXISTS "${module_file_path}")
      ## get module content
      package_cmake_module_content("${package}" "${module}")
      ans(module_content)
      fwrite("${module_file_path}" "${module_content}")
    endif()

    if(NOT EXISTS "${module_dir}/Findcmakepp.cmake")
      cmakepp_config(cmakepp_path)
      ans(cmakepp_path)
      fwrite("${module_dir}/Findcmakepp.cmake" "
        include(\"${cmakepp_path}\")
        " )


    endif()

    return()
  endfunction()





## `(<project handle> <package handle>)-><void>`
##
## **automatically register to package_on_readY"
##
## generates files inside package's content_dir
## this is useful for packages which only consist of metadata
## 
## reads all keys of `package_descriptor.generate : { <<filename template:<string>>:<file content template|cmake function call> }`. 
## These keys are treated as filenames which are formatted using `format(...)` (this allows for customized filenames)
## the property value is interpreted as a template see `template_compile`. or if it exists 
## as a call to a cmake function.
## 
## **scope**
## the following variables are available in the scope for `format` and `template_compile` and calling a function
## * `project : <project handle>`
## * `package : <package handle>`
## 
## **Example**
##
function(package_file_generator project package)
  map_import_properties(${package} package_descriptor content_dir)
  map_tryget("${package_descriptor}" generate)
  ans(generate)

  if(NOT generate)
    return()
  endif()

  map_keys(${generate})
  ans(file_names)
  set(generated_files)
  regex_cmake()
  foreach(file_name ${file_names})
    
    map_tryget(${generate} ${file_name})
    ans(file_content)

    ## ensnure that all scope variables are set
    ## package 
    ## project 
    ## package_descriptor
    ## file_name


    format("${file_name}")
    ans(relative_file_name)

    path_qualify_from("${content_dir}" "${relative_file_name}") 
    ans(file_name)

    set(custom_command false)
    if("${file_content}" MATCHES "^${regex_cmake_command_invocation}")
      set(command "${${regex_cmake_command_invocation.regex_cmake_identifier}}")
      set(args "${${regex_cmake_command_invocation.arguments}}")
      if(COMMAND "${command}")
        data("${args}")
        ans(args)
        format("${args}")
        ans(args)
        call2("${command}" ${args})
        ans(file_content)
        set(custom_command true)
      endif()
    endif()


    if(NOT custom_command)
      template_run("${file_content}")
      ans(file_content)
    endif()
    log("generating file '${relative_file_name}' for '{package.uri}'" --function package_file_generator)
    fwrite("${file_name}" "${file_content}")


    list(APPEND generated_files ${file_name})

  endforeach()

  return_ref(generated_files)


endfunction()


## register package file generator as a event handler for project_on_package_ready
task_enqueue("[]() event_addhandler(project_on_package_ready package_file_generator)")






## 
## 
## hooks:
##   `package_descriptor.cmakepp.hooks.on_dematerializing(<project handle> <packag handle>)`
##     this hook is invoked if it exists. it is invoked before the on_load hook 
##     this means that the project's exports were not loaded when the hook is called
##     however since cmake files are callable you can specify a local path
function(on_dematerializing_hook project_handle package_handle)
  package_handle_invoke_hook("${package_handle}" hooks.on_dematerializing ${project_handle} ${package_handle})
endfunction()






## 
##
## imports all files specified in the package_handle's 
## package_descriptor.cmakepp.export property relative
## to the package_handle.content_dir.  the files are
## included in which they were globbed.
##
## hooks:
##   package_descriptor.cmakepp.hooks.on_load(<project handle> <package handle>):
##     after files were imported the hook stored under 
##     package_descriptor.cmakepp.hooks.on_load is called
##     the value of on_load may be anything callable (file,function lambda)
##     the functions which were exported in the previous step
##     can be such callables. 
## 
##
## events:  
function(on_loaded_hook project_handle package_handle)
  


  ## call on_load hook
  package_handle_invoke_hook(${package_handle} hooks.on_load ${project_handle} ${package_handle})
endfunction()







## `()->` 
##
## **config**
## 
## **hooks**:
##   `package_descriptor.cmakepp.hooks.on_materialized(<project handle> <packag handle>)`
##     this hook is invoked if it exists. it is invoked before the on_load hook 
##     this means that the project's exports were not loaded when the hook is called
##     however since cmake files are callable you can specify a local path
function(on_materialized_hook project_handle package_handle)
  package_handle_invoke_hook("${package_handle}" hooks.on_materialized ${project_handle} ${package_handle})
endfunction()







function(on_ready_hook project_handle package_handle)
  package_handle_invoke_hook("${package_handle}" hooks.on_ready ${project_handle} ${package_handle})
endfunction()








function(on_unloading_hook project_handle package_handle)
  package_handle_invoke_hook(${package_handle} hooks.on_unloading ${project_handle} ${package_handle})
endfunction()





## 
## 
## calls the package_descritpor's `cmakepp.hooks.on_unready` hook if the package is still available
function(on_unready_hook project_handle package_handle)
  map_tryget(${package_handle} materialization_descriptor)
  ans(is_materialized)
  if(is_materialized)
    package_handle_invoke_hook(
      "${package_handle}" 
      hooks.on_unready 
      ${project_handle} 
      ${package_handle}
      )
  endif()
endfunction()





## `(<project>)-><void>`
##
## reads the package descriptor from a project local file if 
## `project_handle.project_descriptor.project_descriptor_file` is configured
function(project_package_descriptor_reader project)
  map_get_map(${project} package_descriptor)
  ans(package_descriptor)

  map_import_properties(${project} project_descriptor content_dir)
  map_import_properties(${project_descriptor} package_descriptor_file)

  if(NOT package_descriptor_file)
    return()
  endif()


  map_set_special(${project_descriptor} project_package_descriptor_was_read true)

  path_qualify_from("${content_dir}" "${package_descriptor_file}")
  ans(package_descriptor_file)


  log("reading package descriptor from '${package_descriptor_file}'" --function project_package_descriptor_reader)
  fread_data("${package_descriptor_file}")
  ans(new_package_descriptor)
  if(new_package_descriptor)
    map_copy_shallow("${package_descriptor}" "${new_package_descriptor}")
  else()
    log("could not read package descriptor from '${package_descriptor_file}'" --function project_package_descriptor_reader)
  endif()

endfunction()






## `(<project>)-><void>`
##  
## writes the package_descriptor to a package_descriptor_file
## it it is configured. does not overwrite package_descriptor_file
## if it was newly set
function(project_package_descriptor_writer project)
  map_import_properties(${project} project_descriptor content_dir)
  map_import_properties(${project_descriptor} package_descriptor_file)
  if(NOT package_descriptor_file)

    return()
  endif()
  map_get_special(${project_descriptor} project_package_descriptor_was_read)
  ans(was_read)


  path_qualify_from("${content_dir}" "${package_descriptor_file}")
  ans(package_descriptor_file)

    
  map_tryget(${project_handle} package_descriptor)
  ans(package_descriptor)

  if(NOT was_read)
    fread_data("${package_descriptor_file}")
    ans(new_package_descriptor)
    if(new_package_descriptor)
      map_copy_shallow(${package_descriptor} ${new_package_descriptor})
    endif()
  endif()


  if(package_descriptor)
    log("writing package descriptor to '${package_descriptor_file}'" --function project_package_descriptor_reader)
    fwrite_data("${package_descriptor_file}" ${package_descriptor})
  endif()


endfunction()





function(project_register_extensions)

  event_addhandler(project_on_open project_package_descriptor_reader)
  event_addhandler(project_on_open project_materialization_check)
  event_addhandler(project_on_open project_loader)

  event_addhandler(project_on_close project_unloader)
  event_addhandler(project_on_close project_package_descriptor_writer)
  
  event_addhandler(project_on_package_ready project_loader)
  event_addhandler(project_on_package_ready on_ready_hook)
  event_addhandler(project_on_package_ready package_dependency_symlinker)

  event_addhandler(project_on_package_dematerializing on_dematerializing_hook)
  event_addhandler(project_on_package_materialized on_materialized_hook)
  
  event_addhandler(project_on_package_loaded cmake_export_handler)
  event_addhandler(project_on_package_loaded on_loaded_hook)
  event_addhandler(project_on_package_loaded project_cmake_export_module)
  event_addhandler(project_on_package_loaded project_cmake_export_config)

  event_addhandler(project_on_package_unloading on_unloading_hook)

  event_addhandler(project_on_package_unready project_unloader)
  event_addhandler(project_on_package_unready "[]() package_dependency_symlinker({{ARGN}} --unlink)")
  event_addhandler(project_on_package_unready on_unready_hook)



endfunction()


## react to ready/unready events
task_enqueue(project_register_extensions)






## `(<project handle> <package handle> [---unlink])-><void>`
##
## adds a symlink from dependees package folder to dependencies content folder 
## the symlink is relative to the package folder and configured in the package's dependency constraints using the symlink property
## 
## `{ id:'mypkg', dependencies:'some-dependency':{symlink:'pkg1'}}` this will cause the content of some-dependency to be symlinked to <package root>/pkg1
## 
## the symlinker is automatically executed when a package becomes ready (and unready)
## 
function(package_dependency_symlinker project package)
  set(args ${ARGN})
  list_extract_flag(args --unlink)
  ans(unlink)
  map_import_properties(${package} dependencies package_descriptor content_dir)
  map_tryget(${package_descriptor} dependencies)
  ans(dependency_constraints)
  if(NOT dependencies)
    return()
  endif()
  
  map_keys(${dependencies})
  ans(dependency_uris)

  ## loop through all admissable uris and get the dependency as well as the constraints
  foreach(dependency_uri ${dependency_uris})
    map_tryget(${dependencies} ${dependency_uri})
    ans(dependency)
    map_tryget(${dependency_constraints} ${dependency_uri})
    ans(constraints)

    ## if the constraints have the symlink property the symlinker
    ## creates a link from the dependee's content_dir/${symlink} to the dependencies ${content_dir}
    map_has(${constraints} symlink)
    ans(has_symlink)
    if(has_symlink)
      map_tryget(${constraints} symlink)
      ans(symlink)

      is_address("${symlink}")
      ans(isref)
      if(NOT isref)
        set(single_link "${symlink}")
        map_new()
        ans(symlink)
        map_set("${symlink}" "${single_link}" ".")
      endif()

      map_keys("${symlink}")
      ans(links)

      foreach(link ${links})          
        map_tryget("${symlink}" "${link}")
        ans(target)

        ## dependency
        ## project 
        ## package
        format("${link}")
        ans(relative_link)
        format("${target}")
        ans(relative_target)

        path_qualify_from("${content_dir}" "${relative_link}")
        ans(link)

        map_tryget(${dependency} content_dir)
        ans(dependency_content_dir)

        path_qualify_from("${dependency_content_dir}" "${relative_target}")
        ans(target)
        ## creates or destroys the link
        if(unlink)
         log("unlinking '${link}' from '${target}' ({package.uri})" --function package_dependency_symlinker)
          unlink("${link}")
        else()
          ## ensure that directory exists
          get_filename_component(dir "${link}" PATH)
          if(NOT EXISTS "${dir}")
            mkdir("${dir}")
          endif()
          log("linking '${link}' to '${target}' ({package.uri})" --function package_dependency_symlinker)
          ln("${target}" "${link}")
          ans(success)
          if(NOT success)
           error("failed to link '${link}' to '${target}' ({package.uri})" --function package_dependency_symlinker)
          endif()
        endif()

      endforeach()
    endif()
  endforeach()
endfunction()






## `(<project>)-><bool>`
##
## @TODO extract dfs algorithm, extreact dependency_load function which works for single dependencies
## 
## loads the specified project and its dependencies
##  
## **events**
## * `project_on_loading`
## * `project_on_loaded`
## * `project_on_package_loading`
## * `project_on_package_loaded`
## * `project_on_package_reload`
## * `project_on_package_cycle`
function(project_load project_handle)
  map_tryget(${project_handle} project_descriptor)
  ans(project_descriptor)

  ## load dependencies
  map_import_properties(${project_descriptor} package_materializations)
  map_values(package_materializations)
  ans(package_materializations)
  set(materialized_packages)
  map_tryget(${project_handle} content_dir)
  ans(project_dir)

  ## set content_dir for every package handle
  ## it is obtained by qualifying the materialization descriptors content_dir
  ## with the project's content_dir
  foreach(materialization ${package_materializations})
    map_tryget(${materialization} package_handle)
    ans_append(materialized_packages)
    ans(package_handle)
    map_tryget(${materialization} content_dir)
    ans(package_dir)
    path_qualify_from(${project_dir} ${package_dir})
    map_set(${package_handle} content_dir ${package_dir})
  endforeach()
  
  
  event_emit(project_on_loading ${project_handle})
  
  map_new()
  ans(context)
  function(__project_load_recurse)

    foreach(package_handle ${ARGN})
      
      map_tryget(${context} ${package_handle})
      ans(state)
      if("${state}_" STREQUAL "visiting_")
        event_emit(project_on_package_cycle ${project_handle} ${package_handle})
      elseif("${state}_" STREQUAL "visited_")
        event_emit(project_on_package_reload ${project_handle} ${package_handle})
      else()
        map_set(${context} ${package_handle} visiting)
          
        ## pre order callback
        event_emit(project_on_package_loading ${project_handle} ${package_handle})
        set(parent_parent_package ${parent_package})
        set(parent_package ${package_handle})
        

        ## expand
        map_tryget(${package_handle} dependencies)
        ans(dependency_map)
        if(dependency_map)
          map_values(${dependency_map})
          ans(dependencies)

          __project_load_recurse(${dependencies})
          
        endif()
        
        map_set(${context} ${package_handle} visited)

        ## post order callback
        set(parent_package ${parent_parent_package})
        event_emit(project_on_package_loaded ${project_handle} ${package_handle})

      endif()
    endforeach()
  endfunction()

  set(parent_parent_package)
  set(parent_package)
  __project_load_recurse(${project_handle} ${materialized_packages})

  event_emit(project_on_loaded ${project_handle})
 
  return(true)
endfunction()








function(project_loader project)
  map_tryget(${project} dependency_descriptor)
  ans(dependency_descriptor)
  map_tryget("${dependency_descriptor}" is_ready)
  ans(is_ready)
  if(NOT is_ready)
    return()
  endif()
  if("${ARGN}_" STREQUAL "_" OR "${project}" STREQUAL "${ARGN}")
    project_load(${project})
  endif()
endfunction()





## `(<project>)-><bool>`
##
## unloads the specified project and its dependencies
##  
## **events**
## * `project_on_unloading`  called before an packages is unloaded
## * `project_on_unloaded`  called after all packages were unloaded
## * `project_on_package_unloading` called before the package's dependencies are unloaded 
## * `project_on_package_unloaded` called after the package's dependencies are unloaded
function(project_unload project_handle)
  ## load dependencies
  map_import_properties(${project_handle} project_descriptor)
  map_import_properties(${project_descriptor} package_materializations)
  map_values(${package_materializations})
  ans(package_materializations)
  ans(package_handles)
  foreach(materialization ${package_materializations})
    map_tryget(${materialization} package_handle)
    ans_append(package_handles)
  endforeach()

  event_emit(project_on_unloading ${project_handle})
  
  map_new()
  ans(context)
  function(__project_unload_recurse)

    foreach(package_handle ${ARGN})
      
      map_tryget(${context} ${package_handle})
      ans(state)
      if("${state}_" STREQUAL "visiting_")
      elseif("${state}_" STREQUAL "visited_")
      else()
        map_set(${context} ${package_handle} visiting)
          
        ## pre order callback
        event_emit(project_on_package_unloading ${project_handle} ${package_handle})
        set(parent_parent_package ${parent_package})
        set(parent_package ${package_handle})
        

        ## expand
        map_tryget(${package_handle} dependencies)
        ans(dependency_map)
        if(dependency_map)
          map_values(${dependency_map})
          ans(dependencies)

          __project_unload_recurse(${dependencies})
          
        endif()
        
        map_set(${context} ${package_handle} visited)

        ## post order callback
        set(parent_package ${parent_parent_package})
        event_emit(project_on_package_unloaded ${project_handle} ${package_handle})

      endif()
    endforeach()
  endfunction()

  set(parent_parent_package)
  set(parent_package)
  __project_unload_recurse(${project_handle} ${package_handles})


  event_emit(project_on_unloaded ${project_handle})
 
  return(true)
endfunction()








function(project_unloader project)
  map_tryget(${project} dependency_descriptor)
  ans(dependency_descriptor)
  map_tryget("${dependency_descriptor}" is_ready)
  ans(is_ready)
  if(NOT is_ready)
    return()
  endif()
  if("${ARGN}_" STREQUAL "_" OR "${project}" STREQUAL "${ARGN}")
    project_unload(${project})
  endif()
endfunction()




## `(<project handle> <materialization handle>)-><bool>`
## 
## checks wether an expected materialization actually exists and is valid
## return true if it is
function(package_materialization_check project_handle package_handle)
  ## if package does not have an materialization descriptor it is not materialized
  map_tryget(${package_handle} materialization_descriptor)
  ans(materialization_handle)
  if(NOT materialization_handle)
    return(false)
  endif()

  map_tryget(${materialization_handle} content_dir )
  ans(package_dir)

  map_tryget("${project_handle}" content_dir)
  ans(project_dir)

  path_qualify_from("${project_dir}" "${package_dir}")
  ans(content_dir)

  package_content_check("${package_handle}" "${content_dir}" )
  return_ans()
endfunction()





## `(<project handle> <package uri>)-><package handle>`
##
## **sideeffects**
## * removes `project_handle.project_descriptor.package_installations.<package_uri>` 
## * removes `package_handle.materialization_descriptor`
## 
##
## **events**:
## * `[pwd=package content dir]project_on_package_dematerializing(<project handle> <package handle>)`
## * `[pwd=package content dir]project_on_package_dematerialized(<project handle> <package handle>)`
## 
function(project_dematerialize project_handle package_uri)
  map_import_properties(${project_handle} project_descriptor)
  map_tryget(${project_handle} uri)
  ans(project_uri)

  map_import_properties(${project_descriptor} 
    package_source
    package_cache
    package_materializations

    )


  ## special treatment for project - dematerialization is allowed
  ## however it will only be virtual and not actualle affect the
  ## content_dir
  if("${project_uri}" STREQUAL "${package_uri}")
    map_tryget(${package_materializations} ${project_uri})
    ans(project_handle)
    map_tryget(${project_handle} content_dir)
    ans(content_dir)
    pushd(${content_dir})
      event_emit(project_on_package_dematerializing ${project_handle} ${project_handle})
        map_remove(${package_materializations} ${project_uri})    
        map_remove(${project_handle} materialization_descriptor)
      event_emit(project_on_package_dematerialized ${project_handle} ${project_handle})
    popd()
    return(${project_handle})
  endif()


  if(NOT package_source)
    message(FATAL_ERROR "project_dematerialize: no package source available")
  endif()

  package_source_resolve(${package_source} ${package_uri} --cache ${package_cache})
  ans(package_handle)

  if(NOT package_handle)
    return()
  endif()

  map_tryget(${package_handle} uri)
  ans(package_uri)

  map_tryget(${package_handle} materialization_descriptor)
  ans(materialization_handle)

  if(NOT materialization_handle)
    return()
  endif() 

  map_tryget(${project_handle} content_dir)
  ans(project_dir)

  map_tryget(${materialization_handle} content_dir)
  ans(package_content_dir)

  path_qualify_from(${project_dir} ${package_content_dir})
  ans(package_content_dir)

  ## emit events before and after removing package
  ## should also work if package doesnot exist anymore
  pushd("${package_content_dir}" --create)  

    event_emit(project_on_package_dematerializing ${project_handle} ${package_handle})

    map_remove(${package_materializations} ${package_uri})
    map_remove(${package_handle} materialization_descriptor)
    ## delete package content dir

    if("${project_dir}" STREQUAL "${package_content_dir}")
      message(WARNING "project_dematerialize: package dir is project dir will not delete")
    else()
      rm(-r "${package_content_dir}")
    endif()


    event_emit(project_on_package_dematerialized ${project_handle} ${package_handle})
  popd()
  return(${package_handle})  
endfunction()





## `(<project handle> <package handle>)-><path>`
##
##  creates a path which tries to be unqiue for the specified pcakge in the project
##
function(project_derive_package_content_dir project_handle package_handle)

  format("{package_handle.package_descriptor.id}")
  ans(package_id)
  string_normalize("${package_id}")
  ans(package_id)

  assign(uri = package_handle.uri)
  uri_coerce(uri)

  map_get("${uri}" scheme)
  ans(scheme)


  format("{project_handle.project_descriptor.dependency_dir}/${scheme}_{package_id}-{package_handle.package_descriptor.version}")
  ans(package_content_dir)
  return_ref(package_content_dir)
endfunction()




## `(<project handle>)-><materialization handle>...`
##
## **events**
## * `project_on_package_materialization_missing`
##
## **sideffects**
## * removes missing materializations from `project_descriptor.package_materializations`
## * removes missing materializations from `package_handle.materialization_descriptor`
##
## checks all materializations of a project 
## if a materialization is missing it is removed from the 
## map of materializations
## returns all invalid materialization handles
function(project_materialization_check project_handle)
  map_import_properties(${project_handle} project_descriptor)
  map_import_properties(${project_descriptor} package_materializations)

  if(NOT package_materializations)
    return()
  endif()
  map_keys(${package_materializations})
  ans(package_uris)

  set(invalid_materializations)
  foreach(package_uri ${package_uris})
    map_tryget("${package_materializations}" "${package_uri}")
    ans(package_handle)
    package_materialization_check("${project_handle}" "${package_handle}")
    ans(ok)
    if(NOT ok)
      project_dematerialize("${project_handle}" "${package_uri}")    
      list(APPEND invalid_materializations ${package_handle})
    endif()
  endforeach()
  return_ref(invalid_materializations)
endfunction() 





## `(<project handle> <volatile uri> <target dir>?)-><package handle>?`
##
## materializes a package for the specified project.
## if the package is already materialized the existing materialization handle
## is returned
## the target dir is treated relative to project root. if the target_dir
## is not given a target dir will be derived e.g. `<project root>/packages/mypackage-0.2.1-alpha`
##
## returns the package handle on success
## 
## **events**: 
## * `[pwd=target_dir]project_on_package_materializing(<project handle> <package handle>)`
## * `[pwd=target_dir]project_on_package_materialized(<project handle> <package handle>)`
##
## **sideffects**:
## * `IN` takes the package from the cache if it exits
## * adds the specified package to the `package cache` if it does not exist 
## * `project_handle.project_descriptor.package_materializations.<package uri> = <materialization handle>`
## * `package_handle.materialization_descriptor = <materialization handle>`
##
## ```
## <materialization handle> ::= {
##   content_dir: <path> # path relative to project root
##   package_handle: <package handle>
## }
## ```
function(project_materialize project_handle package_uri)
  set(args ${ARGN})

  list_pop_front(args)
  ans(package_content_dir)

  map_tryget(${project_handle} uri)
  ans(project_uri)

  map_tryget(${project_handle} project_descriptor)
  ans(project_descriptor)

  map_import_properties(${project_descriptor} 
    package_materializations
    package_source
    package_cache
    dependency_dir
  )

  ## special treatment  if package uri is project uri
  ## project is already materialized however 
  ## events still need to be emitted / materialization_handle 
  ## needs to be created
  if("${project_uri}" STREQUAL "${package_uri}")
    map_tryget(${package_materializations} ${project_uri})
    ans(materialization_handle)
    if(NOT materialization_handle)
      map_new()
      ans(materialization_handle)
      map_set(${materialization_handle} content_dir "")
      map_set(${materialization_handle} package_handle ${project_handle})
      event_emit(project_on_package_materializing ${project_handle} ${project_handle})
      map_set(${package_materializations} "${package_uri}" ${project_handle})
      map_set(${project_handle} materialization_descriptor ${materialization_handle})
      event_emit(project_on_package_materialized ${project_handle} ${project_handle})
    endif()
    return(${project_handle})
  endif()

  if(NOT package_source)
    message(FATAL_ERROR "project_materialize: no package source available")
  endif()

  ## get a package handle from uri
  package_source_resolve(${package_source} "${package_uri}" --cache ${package_cache})
  ans(package_handle)
  if(NOT package_handle)
    return()
  endif()


  map_tryget(${project_handle} content_dir)
  ans(project_dir)

  map_tryget(${package_handle} uri)
  ans(package_uri)

  map_tryget(${package_materializations} ${package_uri})
  ans(is_materialized)

  if(is_materialized)
    return(${package_handle})
  endif()

  
  ## generate the content dir for the package 
  if("${package_content_dir}_" STREQUAL "_")
    project_derive_package_content_dir(${project_handle} ${package_handle})
    ans(package_content_dir)
  endif()
  

  ## create materialization handle
  map_new()
  ans(materialization_handle)
  map_set(${materialization_handle} package_handle ${package_handle})
  map_set(${materialization_handle} content_dir ${package_content_dir})
  map_set(${package_handle} materialization_descriptor ${materialization_handle})

  ## make a qualified path
  path_qualify_from(${project_dir} ${package_content_dir})
  ans(package_content_dir)

  map_set(${package_handle} content_dir ${package_content_dir})

  if("${package_content_dir}" STREQUAL "${project_dir}")
    message(WARNING"project_materialize: invalid package dir '${package_content_dir}'")
    return()
  endif()

  pushd(${installation_dir} --create)

    event_emit(project_on_package_materializing ${project_handle} ${package_handle})

    call(package_source.pull("${package_uri}" "${package_content_dir}"))
    ans(pull_handle)
    ## todo content dir might not be the same
    
    if(NOT pull_handle)
      map_remove(${package_handle} materialization_descriptor)
      popd()
      return()
    endif()

    map_set(${package_materializations} ${package_uri} ${package_handle})

    event_emit(project_on_package_materialized ${project_handle} ${package_handle})
  
  popd()


  return(${package_handle})
endfunction()







function(project_materializer project)
  ## materialize project if it is not materialized
  map_tryget(${project} materialization_descriptor)
  ans(is_materialized)
  if(NOT is_materialized)
    map_tryget(${project} uri)
    ans(project_uri)
    project_materialize(${project} "${project_uri}")
  endif()
endfunction()




## `(<project handle>)-><materialization handle>...`
##
##
## **returns**
## * the `materialization handle`s of all changed packages
##
## **sideffects**
## * see `project_materialize`
## * see `project_dematerialize`
##
## **events**
## * `project_on_dependencies_materializing(<project handle>)`
## * `project_on_dependencies_materialized(<project handle>)`
## * events from `project_materialize` and project `project_dematerialize`
function(project_materialize_dependencies project_handle)
  map_tryget(${project_handle} project_descriptor)
  ans(project_descriptor)
  map_import_properties(${project_descriptor} 
    package_materializations
    dependency_configuration
    installation_queue
    package_cache
    )

  set(changed_packages)

  event_emit(project_on_dependencies_materializing ${project_handle})


  set(current_configuration ${dependency_configuration})
  while(true)
    list_pop_front(installation_queue)
    ans(new_configuration)
    if(NOT new_configuration)
      break()
    endif()
    package_dependency_configuration_changeset(${current_configuration} ${new_configuration})
    ans(changeset)


    map_keys(${changeset})
    ans(package_uris)
    foreach(package_uri ${package_uris})
      map_tryget(${dependency_configuration} ${package_uri})
      ans(state)

      map_tryget(${changeset} ${package_uri})
      ans(action)

      if("${action}" STREQUAL "install")
        project_materialize(${project_handle} ${package_uri})
        ans(package_handle)
      elseif("${action}" STREQUAL "uninstall")
        project_dematerialize(${project_handle} ${package_uri})
        ans(package_handle)
      else()
        message(FATAL_ERROR "project_materialize_dependencies: invalid action `${action}`")    
      endif()

      if(NOT package_handle)
        message(WARNING "failed to materialize/dematerialize dependency ${package_uri}")
      endif()

      list(APPEND changed_packages ${package_handle})
      
    endforeach() 

    #map_pop_front(${project_descriptor} installation_queue)
    map_set(project_descriptor dependency_configuration ${new_configuration})
    set(current_configuration ${new_configuration})
  endwhile()


  ## emit event
  event_emit(project_on_dependencies_materialized ${project_handle})

  ## load the project anew
  project_load(${project_handle})


  return_ref(changed_packages)
endfunction()




## `(<project handle>)-><project file:<path>>`
##
## closes the specified project
##
## **events**
##  * `project_on_closing(<project handle>)`
##  * `project_on_close(<project handle>)`
##  * `project_on_closed(<project handle>)`
function(project_close project_handle)
  project_state_assert("${project_handle}" "opened")

  event_emit(project_on_closing ${project_handle})

  map_tryget(${project_handle} content_dir)
  ans(project_content_dir)

  event_emit(project_on_close ${project_handle})

  pushd("${project_content_dir}" --create)

    ## ensure portability by removing content_dir which is an absolute path
    assign(package_handles = project_handle.project_descriptor.package_materializations)
    map_values(${package_handles})
    ans(package_handles)

    foreach(package_handle ${package_handles})
      map_remove(${package_handle} content_dir)
    endforeach()

    assign(project_file = project_handle.project_descriptor.project_file)
    path_qualify(project_file)

    map_remove("${project}" content_dir)

  popd()

  project_state_change("${project_handle}" "closed")

  event_emit(project_on_closed ${project_handle})

  project_state_assert("${project_handle}" "^closed$")
  return_ref(project_file)
endfunction()





## `(<content_dir> [<~project handle>])-><project handle>` 
##
## opens the specified project by setting default values for the existing or new project handle and setting its content_dir property to the fully qualified path specified.
## if no project handle was given a new one is created.
## if the state of the project handle is `unknown` it was never opened before. It is first transitioned to `closed` after emitting the `project_on_new` event.
## then the project handle is transitioned from `closed` to `open` first the `project_on_opening` event is emitted followed by `project_on_open`.  Afterwards the state is changed to `open` and then the `project_on_opened` event us emitted.  
## returns the project handle of the project on success. fails if the project handle is in a state other than `unknown` or `closed`. 
## 
## *note* that the default project does not contain a package source. it will have to be configured once manually for every new project
##
##
## **events**
##  * `project_on_new(<project handle>)`
##  * `project_on_opening(<project handle>)`
##  * `project_on_open(<project handle>)`
##  * `project_on_opened(<project handle>)`
##  * `project_on_state_enter(<project handle>)`
##  * `project_on_state_leave(<project handle>)`
##  * extensions also emit events.
##
## **assumes** 
## * `project_handle.project_descriptor.state` is either `unknown`(null) or `closed`
## 
## **ensures**
## * `content_dir` is set to the absolute path of the project
## * `project_descriptor.state` is set to `open`
function(project_open content_dir)
  set(args ${ARGN})

  ## try to parse args as structured data
  obj("${args}")
  ans(project_handle)

  ## fill out default necessary values
  project_handle_default()
  ans(project_handle_defaults)
  map_defaults("${project_handle}" "${project_handle_defaults}")
  ans(project_handle)

  ## set content dir
  path_qualify(content_dir)
  map_set(${project_handle} content_dir "${content_dir}")


  ## setup scope
  set(project_dir "${content_dir}")
  

  ## emit events


  ## if project is new emit that event
  project_state_matches("${project_handle}" "^(unknown)$")
  ans(is_new)
  if(is_new)
    event_emit(project_on_new ${project_handle})
    project_state_change("${project_handle}" closed)
  endif()

  
  ## open starting
  event_emit(project_on_opening ${project_handle})
  
  ## open
  event_emit(project_on_open ${project_handle})
  project_state_change("${project_handle}" opened)

  project_state_assert("${project_handle}" "^(opened)$")
  ## open complete
  event_emit(project_on_opened ${project_handle})

  return_ref(project_handle)
endfunction()




## `(<package handle> | <project dir> | <project file>)-><project handle>`
## 
##  Opens a project at `<project dir>` which defaults to the current directory (see `pwd()`). 
##  If a project file is specified it is openend and the project dir is derived.  
## 
##  Checks wether the project is consistent and if not acts accordingly. Loads the project and all its dependencies
##  also loads all materialized packages which are not part of the project's dependency graph
## 
## **returns** 
## * `<project handle>` the handle to the current project (contains the `project_descriptor`) 
## 
## **events**
## * `project_on_opening(<project handle>)` emitted when the `<project handle>` exists but nothing is loaded yet
## * `project_on_open(<project handle>)` emitted  so that custom handlers can perform actions like loading, initializing, etc
## * `project_on_opened(<project handle>)` emitted after the project was checked and loaded
## * events have access to the follwowing in their scope: 
##   * `project_dir:<qualified path>` the location of this projects root directory
##   * `project_handle:<project handle>` the handle to the project 
function(project_read)
  project_constants()
  path("${ARGN}")
  ans(location)
  if(EXISTS "${location}" AND NOT IS_DIRECTORY "${location}")
    set(project_file "${location}")
  else()    
    file_find_anchor("${project_constants_project_file}" ${location})
    ans(project_file)
  endif()

  if(NOT project_file)
    error("no project file found for location '{location}' " --function project_read)
    return()
  endif()


  fread_data("${project_file}")
  ans(project_handle)

  if(NOT project_handle)
    error("not a valid project file '{project_file}' " --function project_read)
    return()
  endif()


  ## derive content dir from configured relative project file path
  assign(project_file_path = project_handle.project_descriptor.project_file)
  if(NOT project_file_path)
    error("project_descriptor.project_file is missing" --function project_read)
    return()
  endif()
  string_remove_ending("${project_file}" "/${project_file_path}")
  ans(content_dir)


  project_open("${content_dir}" "${project_handle}")
  ans(project_handle)



  return_ref(project_handle)
endfunction()





## saves the project 
function(project_write project_handle)
  project_close("${project_handle}")
  ans(project_file)
  fwrite_data("${project_file}" "${project_handle}")
  return_ref(project_file)
endfunction() 




## `()->() *package constants are set` 
##
## defines constants which are used in project management
macro(project_constants)
  if(NOT __project_constants_loaded)
    set(__project_constants_loaded true)
    set(project_constants_dependency_dir "packages")
    set(project_constants_config_dir ".cps")
    set(project_constants_project_file "${project_constants_config_dir}/project.scmake")



  endif()
endmacro()








function(project_descriptor_new)

  map_new()
  ans(package_handle)
  map_set(${package_handle} uri "project")
  map_new()
  ans(package_descriptor)
  map_set(${package_handle} package_descriptor ${package_descriptor})
  map_new()
  ans(package_dependencies)
  map_set(${package_descriptor} dependencies ${package_dependencies})


  foreach(arg ${ARGN})
    if("${arg}" MATCHES "!(.+)")
      map_set("${package_dependencies}" "${CMAKE_MATCH_1}" false)
    else()
      map_set("${package_dependencies}" "${arg}" true)
    endif()
  endforeach()
  return_ref(package_handle)
endfunction()





## `()-><project handle>`
## 
## creates the default project handle:
## ```
## {
##   uri:'project:root',
##   package_descriptor: {}
##   project_descriptor: {
##     package_cache:{}
##     package_materializations:{}
##     dependency_configuration:{}
##     dependency_dir: '${project_constants_dependency_dir}'
##     config_dir: "${project_constants_config_dir}"
##     project_file: "${project_constants_project_file}"
##     package_descriptor_file: <null>
##   }
## }
## ```
function(project_handle_default)
  project_constants()

  map_new()
  ans(package_descriptor)
  map_new()
  ans(project_descriptor)
  map_new()
  ans(package_cache)
  map_new()
  ans(package_materializations)
  map_new()
  ans(dependency_configuration)
  map_set(${project_descriptor} package_cache ${package_cache})
  map_set(${project_descriptor} package_materializations ${package_materializations})
  map_set(${project_descriptor} dependency_configuration ${dependency_configuration})
  map_set(${project_descriptor} dependency_dir "${project_constants_dependency_dir}")
  map_set(${project_descriptor} config_dir "${project_constants_config_dir}")
  map_set(${project_descriptor} project_file "${project_constants_project_file}")

  map_new()
  ans(project_handle)
  map_set(${project_handle} uri "project:root")
  map_set(${project_handle} package_descriptor "${package_descriptor}")
  map_set(${project_handle} project_descriptor "${project_descriptor}")
  
  return_ref(project_handle)
endfunction()




## `()->`
##
## performs the install operation which first optionally changes the dependencies and then materializes
function(project_install project_handle)
  set(args ${ARGN})
  project_change_dependencies(${project_handle} ${args})
  ans(changeset)
 

  project_materialize_dependencies(${project_handle})
  ans(changes_handles)
  
  return(${changeset})
endfunction()





function(project_state project_handle)
  set(new_state ${ARGN})
  if(new_state)
    project_state_change("${project_handle}" "${new_state}")
    ans(state)
  else()
    project_state_get("${project_handle}")
    ans(state)
  endif()
  return_ref(state)
endfunction()







function(project_state_assert project_handle)
  project_state_matches("${project_handle}" "${ARGN}")  
  ans(is_match)
  if(NOT is_match)
    message(FATAL_ERROR FORMAT "invalid project state (expected '${ARGN}' actual '{project_handle.project_descriptor.state}')")
  endif()
endfunction()






function(project_state_change project_handle new_state)
  project_state_get("${project_handle}")
  ans(old_state)
  if("${old_state}_" STREQUAL "${new_state}_")
    return_ref(old_state)
  endif()
  if("${old_state}_" STREQUAL "invalid_")
    message(FATAL_ERROR "invalid state")
  endif()
  set(current_state "${old_state}")
  event_emit(project_on_state_leave ${project_handle} ${old_state} ${new_state})
  assign(!project_handle.project_descriptor.state = new_state)
  set(current_state "${new_state}")
  event_emit(project_on_state_enter ${project_handle} ${old_state} ${new_state})
  return_ref(old_state)
endfunction()






function(project_state_get project_handle)
  if(NOT project_handle)
    return(invalid)
  endif()
  assign(state = project_handle.project_descriptor.state)
  if("${state}_" STREQUAL "_")
    return(unknown)
  endif()
  return_ref(state)
endfunction()







function(project_state_matches project_handle expected_state)
  project_state("${project_handle}")
  ans(actual_state)
  if("${actual_state}" MATCHES "${expected_state}")
    return(true)
  endif()
  return(false)
endfunction()





  function(parse_any rstring)
    # get defintiions for any
    map_get(${definition} any)
    ans(any)

    is_address("${any}")
    ans(isref)
    if(isref)
      address_get(${any})
      ans(any)
    endif()
    # loop through defintions and take the first one that works
    foreach(def_id ${any})
      parse_string("${rstring}" "${def_id}")
      ans(res)

      list(LENGTH res len)
      if("${len}" GREATER 0)
        return_ref(res)
      endif()

    endforeach()

    # return nothing if nothing matched
    return()
  endfunction()






  function(parse_many rstring)
    map_tryget(${definition} begin)
    ans(begin)
    map_tryget(${definition} end)
    ans(end)
    map_tryget(${definition} element)
    ans(element)
    map_tryget(${definition} separator)
    ans(separator)         

    # create copy of input string
    address_get(${rstring})
    ans(str)
    address_set_new("${str}")
    ans(str)

    if(begin)
      parse_string(${str} ${begin})
      ans(res)
      list(LENGTH res len)
      if(${len} EQUAL 0)
        return()
      endif()
    endif()
    set(result_list)
    while(true)

      # try to parse end of list if it was parsed stop iterating
      if(end)
        parse_string(${str} ${end})
        ans(res)
        list(LENGTH res len)
        if(${len} GREATER 0)
          break()
        endif()
      endif()

      if(separator)
        if(result_list)
          parse_string(${str} ${separator})
          ans(res)
          list(LENGTH res len)
          if(${len} EQUAL 0)
            if(NOT end)
              break()
            endif()
            return()
          endif()
        endif()
      endif()

      parse_string("${str}" "${element}")
      ans(res)
      list(LENGTH res len)
      if(${len} EQUAL 0)
        if(NOT end)
          break()
        endif()
        return()
      endif()
      
      list(APPEND result_list "${res}")
    endwhile()    

    # set rstring
    address_get(${str})
    ans(str)
    address_set(${rstring} "${str}")
    
    list(LENGTH return_list len)
    if(NOT len)
      #return("")
    endif()
    return_ref(result_list)
  endfunction()






  function(parse_match rstring)
    address_get(${rstring})
    ans(str)

    map_get(${definition} search)
    ans(search)

   # message("parsing match with '${parser_id}' (search: '${search}') for '${str}'")
    map_tryget(${definition} ignore_regex)
    ans(ignore_regex)
   #message("ignore: ${ignore_regex}")
    list(LENGTH ignore_regex len)
    if(len)
     # message("ignoring ${ignore_regex}")
        string_take_regex(str "${ignore_regex}")
    endif()

    string_take(str "${search}")
    ans(match)

    if(NOT match)
      return()
    endif()

    address_set(${rstring} "${str}")

    return_ref(match)
  endfunction()





function(parse_object rstring)
  
    # create a copy from rstring 
    address_get(${rstring})
    ans(str)
    address_set_new("${str}")
    ans(str)

    # get definitions
    map_tryget(${definition} begin)
    ans(begin_id)

    map_tryget(${definition} end)
    ans(end_id)
    
    map_tryget(${definition} keyvalue)
    ans(keyvalue_id)

    map_tryget(${definition} separator)
    ans(separator_id)         

    if(begin_id)
      parse_string(${str} ${begin_id})
      ans(res)
      list(LENGTH res len)
      if(${len} EQUAL 0)
        return()
      endif()
    endif()

    map_new()
    ans(result_object)

    set(has_result)

    while(true)
      # try to parse end of list if it was parsed stop iterating
      if(end_id)
        parse_string(${str} "${end_id}")
        ans(res)

        list(LENGTH res len)
        if(${len} GREATER 0)
          break()
        endif()
      endif()

      if(separator_id)
        if(has_result)
          parse_string(${str} "${separator_id}")
          ans(res)
          list(LENGTH res len)
          if(${len} EQUAL 0)
            if(NOT end)
              break()
            endif()
            return()
          endif()
        endif()
      endif()

      parse_string(${str} "${keyvalue_id}")
      ans(keyvalue)

      if(NOT keyvalue)
        if(NOT end)
          break()
        endif()
        return()
      endif()

      map_get(${keyvalue} key)
      ans(object_key)

      map_get(${keyvalue} value)
      ans(object_value)

      if(NOT has_result)
        set(has_result true)
      endif()

      if("${object_value}_" STREQUAL "_")
        
        set(object_value "")
      endif()
      
      map_set("${result_object}" "${object_key}" "${object_value}")

    endwhile()    


    # if every element was  found set rstring to rest of string
    address_get(${str})
    ans(str)
    address_set(${rstring} "${str}")

    # return result
    return_ref(result_object)
endfunction()




 function(parse_ref rstring)
    address_get(${rstring})
    ans(str)
    string_take_regex(str ":[a-zA-Z0-9_-]+")
    ans(match)
    if(NOT DEFINED match)
      return()
    endif()
  #  message("match ${match}")
    is_address("${match}")
    ans(isvalid)

    if(NOT  isvalid)
      return()
    endif()



    map_tryget(${definition} matches)
    ans(matches)
    #json_print(${matches})
    is_map(${matches})
    ans(ismap)

    if(NOT ismap)
      address_get(${match})
      ans(ref_value)

      if("${matches}" MATCHES "${ref_value}")
        return_ref(match)
      endif()
      return()
    else()
      map_keys(${matches})
      ans(keys)
      foreach(key ${keys})
        map_tryget(${match} "${key}")
        ans(val)

        map_tryget(${matches} "${key}")
        ans(regex)

        if(NOT "${val}" MATCHES "${regex}")
          return()
        endif()
      endforeach()
    endif()
    address_set(${rstring} "${str}")
    return_ref(match)
  endfunction()





  function(parse_regex rstring)
    # deref rstring
    address_get(${rstring})
    ans(str)
   # message("string ${str}")
    # get regex from defintion
    map_get(${definition} regex)
    ans(regex)
   # message("${regex}")

 #   message("parsing '${parser_id}' parser (regex: '${regex}') for '${str}'")
    # try to take regex from string
    
    map_tryget(${definition} ignore_regex)
    ans(ignore_regex)
   # message("ignore: ${ignore_regex}")
    list(LENGTH ignore_regex len)
    if(len)
   # message("ignoring ${ignore_regex}")
        string_take_regex(str "${ignore_regex}")
    endif()
#   message("str is '${str}'")
    string_take_regex(str "${regex}")
    ans(match)

    #message("match ${match}")
    # if not success return
    list(LENGTH match len)
    if(NOT len)
      return()
    endif()
 #   message("matched '${match}'")

    map_tryget(${definition} replace)
    ans(replace)
    if(replace)        
        string_eval("${replace}")
        ans(replace)
        #message("replace ${replace}")
        string(REGEX REPLACE "${regex}" "${replace}" match "${match}")
        #message("replaced :'${match}'")

    endif()

    map_tryget(${definition} transform)
    ans(transform)
    if(transform)
        #message("transforming ")
        call("${transform}"("match"))
        ans(match)
    endif()

    if("${match}_" STREQUAL "_")
        set(match "")
    endif()
    # if success set rstring to rest of string
    address_set(${rstring} "${str}")

    # return matched element
    return_ref(match)
  endfunction()





  function(parse_sequence rstring) 
    # create a copy from rstring 
    address_get(${rstring})
    ans(str)
    address_set_new("${str}")
    ans(str)

    # get sequence definitions
    map_get(${definition} sequence)
    ans(sequence)

    map_keys(${sequence})
    ans(sequence_keys)

    function(eval_sequence_expression rstring key res_map expression set_map)
      is_map("${expression}")
      ans(ismap)

      if(ismap)
        map_new()
        ans(definition)

        map_set(${definition} "parser" "sequence")
        map_set(${definition} "sequence" "${expression}")
        
#        json_print(${definition})
        parse_sequence("${rstring}")
        ans(res)

        if("${res}_" STREQUAL "_")
          return(false)
        endif()

        map_set(${result_map} "${key}" ${res})
        map_set(${set_map} "${key}" true)
        return(true)

      endif()      



      #message("Expr ${expression}")
      if("${expression}" STREQUAL "?")
        return(true)
      endif()
      # static value
      if("${expression}" MATCHES "^@")
        string(SUBSTRING "${expression}" 1 -1 expression)
        map_set("${res_map}" "${key}" "${expression}")
        return(true)
      endif()
      
      # null coalescing
      if("${expression}" MATCHES "[^@]*\\|")
        string_split_at_first(left right "${expression}" "|")
        eval_sequence_expression("${rstring}" "${key}" "${res_map}" "${left}" "${set_map}")
        ans(success)
        if(success)
          return(true)
        endif()
       # message("parsing right")
        eval_sequence_expression("${rstring}" "${key}" "${res_map}" "${right}" "${set_map}")
        return_ans()
      endif()

      # ternary operator ? :
      if("${expression}" MATCHES "[a-zA-Z0-9_-]+\\?.+")
        string_split_at_first(left right "${expression}" "?")
        set(else)
        if(NOT "${right}" MATCHES "^@")
          string_split_at_first(right else "${right}" ":")
        endif()
        map_tryget(${set_map} "${left}")
        ans(has_value)
        if(has_value)
          eval_sequence_expression("${rstring}" "${key}" "${res_map}" "${right}" "${set_map}")
          ans(success)
          if(success)
            return(true)
          endif()
          return(false)
        elseif(DEFINED else)
          eval_sequence_expression("${rstring}" "${key}" "${res_map}" "${else}" "${set_map}")
          ans(success)
          if(success)
            return(true)
          endif()

          return(false)
        else()
          return(true)
        endif()

      endif() 



      set(ignore false)
      set(optional false)
      set(default)


      if("${expression}" MATCHES "^\\?")
        string(SUBSTRING "${expression}" 1 -1 expression)
        set(optional true)
      endif()
      if("${expression}" MATCHES "^/")
        string(SUBSTRING "${expression}" 1 -1 expression)
        set(ignore true)
      endif()


      parse_string("${rstring}" "${expression}")
      ans(res)

      list(LENGTH res len)


      if(${len} EQUAL 0 AND NOT optional)
        return(false)
      endif()

      if(NOT "${ignore}" AND DEFINED res)
   #     message("setting at ${key}")
        map_set("${res_map}" "${key}" "${res}")
      endif()
      
      if(NOT ${len} EQUAL 0)
        map_set(${set_map} "${key}" "true")

      endif()
      return(true)
    endfunction()

    # match every element in sequence
    map_new()
    ans(result_map)

    map_new()
    ans(set_map)


    foreach(sequence_key ${sequence_keys})

      map_tryget("${sequence}" "${sequence_key}")
      ans(sequence_id)

      eval_sequence_expression("${str}" "${sequence_key}" "${result_map}" "${sequence_id}" "${set_map}")
      ans(success)
      if(NOT success)
        return()
      endif()
    endforeach()




    # if every element was  found set rstring to rest of string
    address_get(${str})
    ans(str)
    address_set(${rstring} "${str}")

    # return result
    return_ref(result_map)
  endfunction()



#    foreach(sequence_key ${sequence_keys})
#
#      map_tryget("${sequence}" "${sequence_key}")
#      ans(sequence_id)
#
#      if("${sequence_id}" MATCHES "^@")
#        string(SUBSTRING "${sequence_id}" 1 -1 sequence_id)
#        map_set("${result_map}" "${sequence_key}" "${sequence_id}")
#     
#      else()
#        set(ignore false)
#        set(optional false)
#        if("${sequence_id}" MATCHES "^\\?")
#          string(SUBSTRING "${sequence_id}" 1 -1 sequence_id)
#          set(optional true)
#        endif()
#        if("${sequence_id}" MATCHES "^/")
#          string(SUBSTRING "${sequence_id}" 1 -1 sequence_id)
#          set(ignore true)
#        endif()
#
#
#        parse_string("${str}" "${sequence_id}")
#        ans(res)
#
#        list(LENGTH res len)
#
#
#        if(${len} EQUAL 0 AND NOT optional)
#          return()
#        endif()
#
#        if(NOT "${ignore}")
#          map_set("${result_map}" "${sequence_key}" "${res}")
#        endif()
#      endif()
#    endforeach()




  function(parse_string rstring definition_id)
    # initialize
    if(NOT __parse_string_initialized)
      set(args ${ARGN})
      set(__parse_string_initialized true)
      list_extract(args definitions parsers language)
      function_import_table(${parsers} __call_string_parser)
    endif()

    # 
    map_get("${definitions}" "${definition_id}")
    ans(definition)
    
    #
    map_get("${definition}" parser)
    ans(parser_id)
    
    #
  #  message(FORMAT "${parser_id} parser parsing ${definition_id}..")
    message_indent_push()
    __call_string_parser("${parser_id}" "${rstring}")
    ans(res)
    message_indent_pop()
   # message(FORMAT "${parser_id} parser returned: ${res} rest is")
   #list(LENGTH res len)
 #  if(len)
   #  message("parsed '${res}' with ${parser_id} parser")
   #endif()   
    return_ref(res)
  endfunction()





  function(fallback_data_get dirs id)
    set(res)
    foreach(dir ${dirs})
      file_data_get("${dir}" "${id}" ${ARGN})
      ans(res)
      if(res)
        break()
      endif()
    endforeach()
    return_ref(res)
  endfunction()








  function(fallback_data_read dirs id)    
    set(maps )
    foreach(dir ${dirs})
      file_data_read("${dir}" "${id}")
      ans(res)
      list(APPEND maps "${res}")
    endforeach()
    list(REVERSE maps)
    map_merge(${maps})
    ans(res)
    return_ref(res)
  endfunction()







  function(fallback_data_set dirs id nav)
    list_pop_front(dirs)
    ans(dir)

    file_data_set("${dir}" "${id}" "${nav}" ${ARGN})
    return_ans()
  endfunction()




## returns the source dir for the specified navigation argument
function(fallback_data_source dirs id)
  set(res)
  foreach(dir ${dirs})
    file_data_get("${dir}" "${id}" ${ARGN})
    ans(res)
    if(res)
      return_ref(dir)
    endif()
  endforeach()
  return()
endfunction()






function(file_data_clear dir id)
  file_data_path("${dir}" "${id}")
  ans(path)
  if(NOT EXISTS "${path}")
    return(false)
  endif()
  rm("${path}")
  return(true)
endfunction()





## returns all identifiers for specified file data directory
function(file_data_ids dir)
  path("${dir}")
  ans(dir)
  glob("${dir}/*.cmake")

  ans(files)
  set(keys)
  foreach(file ${files})
    path_component("${file}" --file-name)
    ans(key)
    list(APPEND keys "${key}")
  endforeach()
  return_ref(keys)
endfunction()






function(file_data_get dir id)
  set(nav ${ARGN})
  file_data_read("${dir}" "${id}")
  ans(res)
  if("${nav}_" STREQUAL "_" OR "${nav}_" STREQUAL "._")
    return_ref(res)
  endif()
  nav(data = "res.${nav}")
  return_ref(data)
endfunction()







function(file_data_path dir id)
  path("${dir}/${id}.cmake")
  ans(path)
  return_ref(path)    
endfunction()






function(file_data_read dir id)
  file_data_path("${dir}" "${id}")      
  ans(path)
  if(NOT EXISTS "${path}")
    return()
  endif()
  qm_read("${path}")
  return_ans()
endfunction()







function(file_data_set dir id nav)
  set(args ${ARGN})

  if("${nav}" STREQUAL "." OR "${nav}_" STREQUAL "_")
    file_data_write("${dir}" "${id}" ${ARGN})
    return_ans()
  endif()
  file_data_read("${dir}" "${id}")
  ans(res)
  map_navigate_set("res.${nav}" ${ARGN})
  file_data_write("${dir}" "${id}" ${res})
  return_ans()
endfunction()


   
  







function(file_data_write dir id)
  file_data_path("${dir}" "${id}")
  ans(path)
  qm_write("${path}" ${ARGN})
  return_ref(path)
endfunction()





  ## same as file_data_write except that an <obj> is parsed 
  function(file_data_write_obj dir id obj)
    obj("${obj}")
    ans(obj)
    file_data_write("${dir}" "${id}" "${obj}")
    return_ans()
  endfunction()





## `(<search file:<file name>> [<location:<path>>])-><path>|<null>`
##
## an anchor file is what I call a file that exists somewhere in the
## specified location, any parent directory, or in the current directory
## for example git normally uses an anchorfile in every repository
## (in that cast the `.git` folder)
## also alot of projects use a local file system and in the project;'s
## root folder there exists an anchor file e.g. `.cps` `.cps/project.scmake` 
##
function(file_find_anchor search_file)
  set(search ${ARGN})
  path("${search}")
  ans(search)
  set(current_path "${search}")
  set(last_path)
  while(true)
    if("${last_path}_" STREQUAL "${current_path}_")
      return()
    endif()
    set(anchor_file "${current_path}/${search_file}")
    if(EXISTS "${anchor_file}")
      break()
    endif()
    set(last_path "${current_path}")
    path_parent_dir("${current_path}")
    ans(current_path)
  endwhile()
  return_ref(anchor_file)
endfunction()






  function(indexed_store store_dir)
    path_qualify(store_dir)
    ans(store_dir)

    map_new()
    ans(this)
    assign(this.store_dir = store_dir)
    assign(this.save = 'indexed_store_save')
    assign(this.load = 'indexed_store_load')
    assign(this.index_add = 'indexed_store_index_add')
    assign(this.find_keys = 'indexed_store_find_keys')
    assign(this.find = 'indexed_store_find')
    assign(this.delete = 'indexed_store_delete')
    assign(this.list = 'indexed_store_list')
    assign(this.keys = 'indexed_store_keys')
    assign(this.key = '')
    return(${this})
  endfunction()


  function(indexed_store_list)
    indexed_store_keys()
    ans(keys)
    set(itms)
    foreach(key ${keys})
      indexed_store_load(${key})
      ans_append(itms)
    endforeach()
    return_ref(itms)
  endfunction()







function(indexed_store_delete)
  set(key ${ARGN})
  this_get(store_dir)
  file(GLOB files "${store_dir}/*${key}*")
  if(NOT files)
    return(false)
  endif()
  file(REMOVE ${files})
  return(true)
endfunction()








  function(indexed_store_find)
    indexed_store_find_keys("${ARGN}")
    ans(keys)
    set(result)
    foreach(key ${keys})
      assign(result[] = this.load("${key}"))
    endforeach()
    return_ref(result)
  endfunction()





  function(indexed_store_find_keys)
    set(keys)
    this_get(store_dir)

    set(globs)
    foreach(query ${ARGN})
      checksum_string("${query}")
      ans(hash)
      list(APPEND globs "${store_dir}/${hash}*")
    endforeach()
    if(NOT globs)
      return()
    endif()

    file(GLOB store_keys RELATIVE "${store_dir}" ${globs})
    string(REGEX REPLACE "([a-fA-F0-9]+)-([a-fA-F0-9]+)-([a-fA-F0-9]+)" "\\2" keys "${store_keys}")
  
    list_remove_duplicates(keys)
    return_ref(keys)
  endfunction()
  







  function(indexed_store_index_add)
    obj("${ARGN}")
    ans(index)
    if(NOT index)
      map_new()
      ans(index)
      map_set(${index} name "${ARGN}")
      set(selector "[]() ref_nav_get({{ARGN}} '${ARGN}')")
    else()
      map_tryget(${index} selector)
      ans(selector)
    endif()  
    callable("${selector}")
    ans(selector)
    map_set(${index} selector "${selector}")
    assign(this.indices[] = index)
    return_ref(index)
  endfunction()





function(indexed_store_keys)
  this_get(store_dir)
  file(GLOB keys RELATIVE "${store_dir}" "${store_dir}/*" )
  string(REGEX REPLACE "[a-fA-F0-9]+-([a-fA-F0-9]+)-[a-fA-F0-9]+" "\\1" keys "${keys}")
  
  list_remove_duplicates(keys)
  return_ref(keys)
endfunction()





function(indexed_store_load )
  set(key ${ARGN})
  this_get(store_dir)
  set(path "${store_dir}/${key}-${key}-${key}")
  if(NOT EXISTS "${path}")
    return()
  endif()
  cmake_read("${path}")
  return_ans()

endfunction()





  function(indexed_store_save )
    this_get(indices)
    this_get(store_dir)
    cmake_serialize("${ARGN}")
    ans(serialized)

    this_get(key)
    if(key)
      call2("${key}" ${ARGN})
      ans(key_value)
      checksum_string("${key_value}")
      ans(key)
    else()
      checksum_string("${serialized}")
      ans(key)
    endif()


    set(store_key "${key}-${key}-${key}")
    fwrite("${store_dir}/${store_key}" "${serialized}")
    foreach(index ${indices})
      map_get(${index} name)
      ans(name)
      map_get(${index} selector)
      ans(selector)
      call2("${selector}" "${ARGN}")
      ans(value)
      if(NOT "${value}_" STREQUAL "_")
        checksum_string("${name}==${value}")
        ans(hash)
        checksum_string("${name}")
        ans(index_hash)
        set(index_key "${store_dir}/${hash}-${key}-${index_hash}")
        fwrite("${index_key}" "${value}")
      endif()
    endforeach()
    return_ref(key)
  endfunction()







  function(key_value_store key_function)
    set(args ${ARGN})
    list_pop_front(args)
    ans(store_dir)

    path_qualify(store_dir)

    map_new()
    ans(this)

    assign(this.store_dir = store_dir)
    assign(this.save = 'key_value_store_save')
    assign(this.load = 'key_value_store_load')
    assign(this.list = 'key_value_store_list')
    assign(this.keys = 'key_value_store_keys')
    assign(this.delete = 'key_value_store_delete')
    assign(this.key = key_function)
    return(${this})
  endfunction()





  function(key_value_store_delete key)
    this_get(store_dir)
    if(EXISTS "${store_dir}/${key}")
      rm("${store_dir}/${key}")
      return(true)
    endif()
    return(false)
  endfunction()






  function(key_value_store_keys)
    this_get(store_dir)
    file(GLOB keys RELATIVE "${store_dir}" "${store_dir}/*")
    return_ref(keys)
  endfunction()






  function(key_value_store_list)
    key_value_store_keys()
    ans(keys)
    set(values)
    foreach(key ${keys})
      key_value_store_load("${key}")
      ans_append(values)
    endforeach()  
    return_ref(values)
  endfunction()

  





  function(key_value_store_load key)
    this_get(store_dir)
    if(NOT EXISTS "${store_dir}/${key}")
      return()
    endif()
    qm_read("${store_dir}/${key}")
    return_ans()
  endfunction()






  function(key_value_store_save)
    this_get(store_dir)
    assign(key = this.key(${ARGN}))
    qm_write("${store_dir}/${key}" ${ARGN})    
    return_ref(key)
  endfunction()




## signature user_data_clear(<id:identifier>^"--all")
### removes the user data associated to identifier id
## WARNING: if --all flag is specified instead of an id all user data is deleted
## 
function(user_data_clear)
  set(args ${ARGN})
  list_extract_flag(args --all)
  ans(all)
  set(id ${args})
  if(all)
    user_data_ids()
    ans(ids)
    foreach(id ${ids})
      user_data_clear("${id}")
    endforeach()
  endif()
  user_data_path("${id}")
  ans(res)
  if(EXISTS "${res}")
    rm("${res}")
    return(true)
  endif()
  return(false)
endfunction()





## returns the <qualified directory> where the user data is stored
# this is the home dir/.cmakepp
function(user_data_dir)    
  home_dir()
  ans(home_dir)
  set(storage_dir "${home_dir}/.cmakepp")
  if(NOT EXISTS "${storage_dir}")
    mkdir("${storage_dir}")
  endif()
  return_ref(storage_dir)
endfunction()





## returns data (read from storage) for the current user which is identified by <id>
## if no navigation arg is specified then the root data is returned
## else a navigation expression can be specified which returns a specific VALUE
## see nav function
function(user_data_get id)
  set(nav ${ARGN})
  user_data_read("${id}")
  ans(res)
  if("${nav}_" STREQUAL "_" OR "${nav}_" STREQUAL "._")
    return_ref(res)
  endif()
  nav(data = "res.${nav}")
  return_ref(data)
endfunction()




## returns all identifiers for user data
function(user_data_ids)
  user_data_dir()
  ans(dir)
  glob("${dir}/*.cmake")
  ans(files)
  set(keys)
  foreach(file ${files})
    path_component("${file}" --file-name)
    ans(key)
    list(APPEND keys "${key}")
  endforeach()
  return_ref(keys)
endfunction()




## returns the user data path for the specified id
## id can be any string that is also usable as a valid filename
## it is located in %HOME_DIR%/.cmakepp
function(user_data_path id)  
  if(NOT id)
    message(FATAL_ERROR "no id specified")
  endif()
  user_data_dir()
  ans(storage_dir)
  set(storage_file "${storage_dir}/${id}.cmake")
  return_ref(storage_file)
endfunction()






### returns the user data stored under the index id
## user data may be any kind of data  
function(user_data_read id)
  user_data_path("${id}")
  ans(storage_file)

  if(NOT EXISTS "${storage_file}")
    return()
  endif()

  qm_read("${storage_file}")
  return_ans()
endfunction()




## sets and persists data for the current user specified by identified by <id> 
## nav can be empty or a "." which will set the data at the root level
## else it can be a navigation expressions which (see map_navigate_set)
## e.g. user_data_set(common_directories cmakepp.base_dir /home/user/mydir)
## results in common_directories to contain
## {
##   cmakepp:{
##     base_dir:"/home/user/mydir"
##   }
## }
function(user_data_set id nav)
  set(args ${ARGN})

  if("${nav}" STREQUAL "." OR "${nav}_" STREQUAL "_")
    user_data_write("${id}" ${ARGN})
    return_ans()
  endif()
  user_data_read("${id}")
  ans(res)
  map_navigate_set("res.${nav}" ${ARGN})
  user_data_write("${id}" ${res})
  return_ans()
endfunction()






## writes all var args into user data, accepts any typ of data 
## maps are serialized
function(user_data_write id)
  user_data_path("${id}")
  ans(path)
  qm_write("${path}" ${ARGN})
  return_ans()
endfunction()






  ## same as user_data_write except that an <obj> is parsed 
  function(user_data_write_obj id obj)
    obj("${obj}")
    ans(obj)
    user_data_write("${id}" "${obj}")
    return_ans()
  endfunction()






# wraps the the win32 bash shell if available (Cygwin)
function(win32_bash)
  find_package(Cygwin )
  if(NOT Cygwin_FOUND)
    message(FATAL_ERROR "Cygwin was not found on your system")
  endif()
  wrap_exectuable(win32_bash "${Cygwin_EXECUTABLE}")
  win32_bash(${ARGN})
  return_ans()
endfunction()





# wraps the win32 console executable cmd.exe
function(win32_cmd)
  wrap_executable(win32_cmd cmd.exe)
  win32_cmd(${ARGN})
  return_ans()
endfunction()







function(win32_cmd_lean)
  wrap_executable_bare(win32_cmd_lean cmd.exe)
  win32_cmd_lean(${ARGN})
  return_ans()
endfunction()







# wraps the win32 console executable cmd.exe
function(msiexec)
  if(NOT WIN32)
    message(FATAL_ERROR "not supported on your os - only Windows")
  endif()
  wrap_executable(msiexec msiexec.exe)
  msiexec(${ARGN})
  return_ans()
endfunction()






#
function(msiexec_lean)
    if(NOT WIN32)
    message(FATAL_ERROR "not supported on your os - only Windows")
  endif()

  wrap_executable_bare(msiexec_lean msiexec.exe)
  msiexec_lean(${ARGN})
  return_ans()
endfunction()





## `()-><ms guid>`
##
## queries the windows registry for packages installed with msi
## returns their ids (which are microsoft guid)
function(msi_package_ids)
  reg_lean(query "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
  ans_extract(error)
  ans(entries)
  if(error)
    message(FATAL_ERROR "could not query register for msi installed packages")
  endif()
  string(REPLACE "\n" ";" entries "${entries}")
  regex_common()

  set(installations)
  foreach(entry ${entries})
    if("${entry}" MATCHES "\\\\(${regex_guid_ms})$")
      list(APPEND installations "${CMAKE_MATCH_1}")
    endif()
  endforeach()
  return_ref(installations)
endfunction()





  ## wraps the win32 powershell command
  function(win32_powershell)
    wrap_executable(win32_powershell PowerShell)
    win32_powershell(${ARGN})
    return_ans()
  endfunction()






## creates a  powershell array from the specified args
function(win32_powershell_create_array)

    ## compile powershell array for argument list
    set(arg_list)
    foreach(arg ${ARGN})
      string_encode_delimited("${arg}" \")
      ans(arg)
      list(APPEND arg_list "${arg}")
    endforeach()
    string_combine("," ${arg_list})
    ans(arg_list)
    set("${arg_list}" "@(${arg_list})")

    return_ref(arg_list)

endfunction()





## wraps the win32 powershell command in a lean wrapper
function(win32_powershell_lean)
  wrap_executable_bare(win32_powershell_lean PowerShell)
  win32_powershell_lean(${ARGN})
  return_ans()
endfunction()






  ## runs the specified code as a powershell script
  ## and returns the result
  function(win32_powershell_run_script code)
    mktemp()
    ans(path)

    fwrite("${path}/script.ps1" "${code}")
    ans(script_file)
    win32_powershell(
      -NoLogo                   # no info output 
      -NonInteractive           # no interaction
      -ExecutionPolicy ByPass   # bypass execution policy 
     # -NoNewWindow              
      #-WindowStyle Hidden       # hide window
      -File "${script_file}"    # the file to execute
      ${ARGN}                   # add further args to command line
      )
    return_ans()
  endfunction()





# wraps the win32 taskkill command
function(win32_taskkill)
  wrap_executable(win32_taskkill "taskkill")
  win32_taskkill(${ARGN})
  return_ans()
endfunction()




## wraps the windows task lisk programm which returns process info
function(win32_tasklist)
  wrap_executable(win32_tasklist "tasklist")
  win32_tasklist(${ARGN})
  return_ans()
endfunction()





## a bare wrapper for tasklist
function(win32_tasklist_bare)
  wrap_executable_bare(win32_tasklist_bare "tasklist")
  win32_tasklist_bare(${ARGN})
  return_ans()
endfunction()





## wraps the windows wmic command (windows XP and higher )
# since wmic does outputs unicode and does not take forward slash paths the usage is more complicated 
# and wrap_executable does not work
function(win32_wmic)
  pwd()
  ans(pwd)
  fwrite_temp("")
  ans(tmp)
  file(TO_NATIVE_PATH "${tmp}" out)

  execute_process(COMMAND wmic /output:${out} ${ARGN} RESULT_VARIABLE res WORKING_DIRECTORY "${pwd}")  
  if(NOT "${res}" EQUAL 0 )
    return()
  endif()

  fread_unicode16("${tmp}")        
  return_ans()
endfunction()





# returns a <process handle>
# currently does not play well with arguments
function(win32_wmic_call_create command)
  path("${command}")
  ans(cmd)
  pwd()
  ans(cwd)  
  set(args)


  message("cmd ${cmd}")
  file(TO_NATIVE_PATH "${cwd}" cwd)
  file(TO_NATIVE_PATH "${cmd}" cmd)


  if(ARGN)
    string(REPLACE ";" " " args "${ARGN}")
    set(args ",${args}")
  endif()
  win32_wmic(process call create ${cmd},${cwd})#${args}
  ans(res)
  set(pidregex "ProcessId = ([1-9][0-9]*)\;")
  set(retregex "ReturnValue = ([0-9]+)\;")
  string(REGEX MATCH "${pidregex}" pid_match "${res}")
  string(REGEX MATCH "${retregex}" ret_match "${res}")

  string(REGEX REPLACE "${retregex}" "\\1" ret "${ret_match}")
  string(REGEX REPLACE "${pidregex}" "\\1" pid "${pid_match}")
  if(NOT "${ret}" EQUAL 0)
    return()
  endif() 
  process_handle(${pid})
  ans(res)
  map_set(${res} status running)
  return_ref(res)
endfunction()




## async(<callable>(<args...)) -> <process handle>
##
## executes a callable asynchroniously 
##
## todo: 
##   capture necessary scope vars
##   include further files for custom functions     
##   environment vars
  function(async callable)
    cmakepp_config(base_dir)
    ans(base_dir)
    set(args ${ARGN})
    list_pop_front(args)
    list_pop_back(args)
    qm_serialize(${args})
    ans(arguments)
    path_temp()
    ans(result_file)
    pwd()
    ans(pwd)
    set(code
      "
        include(\"${base_dir}/cmakepp.cmake\")
        cd(\"${pwd}\")
        ${arguments}
        ans(arguments)
        address_get(\"\${arguments}\")
        ans(arguments)
        function_import(\"${callable}\" as __async_call)
        message(\${arguments})
        __async_call(\${arguments})
        ans(async_result)
        qm_write(\"${result_file}\" \"\${async_result}\")
      ")
    process_start_script("${code}")
    ans(process_handle)
    map_set(${process_handle} result_file "${result_file}")
    return_ref(process_handle)
  endfunction()






  function(await handle)
    process_wait(${handle})

    map_tryget("${handle}" result_file)
    ans(result_file)
    qm_read("${result_file}")
    return_ans()
  endfunction()





function(command_line)
  is_map("${ARGN}")
  ans(ismap)
  if(ismap)
    map_has("${ARGN}" command)
    ans(iscommand_line)
    if(iscommand_line)
      return("${ARGN}")
    endif()
    return()
  endif()
  command_line_parse(${ARGN})
  return_ans()


endfunction()




## combines the list of command line args into a string which separates and escapes them correctly
  function(command_line_args_combine)
    command_line_args_escape(${ARGN})
    ans(args)
    string_combine(" " ${args})
    ans(res)
    string_decode_list("${res}")
    ans(res)    
    return_ref(res)
  endfunction()





## escapes a command line quoting arguments as needed 
function(command_line_args_escape) 
  set(whitespace_regex "( )")
  set(result)
  
  string(ASCII  31 us)

  foreach(arg ${ARGN})
    string(REGEX MATCH "[\r\n]" m "${arg}")
    if(NOT "_${m}" STREQUAL "_")
      message(FATAL_ERROR "command line argument '${arg}' is invalid - contains CR NL - consider escaping")
    endif()

    string(REGEX MATCH "${whitespace_regex}|\"" m "${arg}")
    if("${arg}" MATCHES "${whitespace_regex}|\"")
      string(REPLACE "\"" "\\\"" arg "${arg}")
      set(arg "\"${arg}\"")
    elseif("${arg}" MATCHES "${us}")
      set(arg "\"${arg}\"")
    endif()




    list(APPEND result "${arg}")

  endforeach()    
  return_ref(result)
endfunction()





## command_line_parse 
## parses the sepcified cmake style  command list which starts with COMMAND 
## or parses a single command line call
## returns a command line object:
## {
##   command:<string>,
##   args: <string>...
## }
function(command_line_parse)
  set(args ${ARGN})

  if(NOT args)
    return()
  endif()


  list_pop_front(args)
  ans(first)

  list(LENGTH args arg_count)

  if("${first}_" STREQUAL "COMMAND_")
    list_pop_front(args)
    ans(command)

    command_line_args_combine(${args})
    ans(arg_string)


    set(command_line "\"${command}\" ${arg_string}")      
  else()
    if(arg_count)
     message(FATAL_ERROR "either use a single command string or a list of 'COMMAND <command> <arg1> <arg2> ...'")
    endif()
    set(command_line "${first}")
  endif()


  command_line_parse_string("${command_line}")
  return_ans()
endfunction()






  function(command_line_parse_string str)
    uri_parse("${str}")
    ans(uri)

    map_tryget(${uri} rest)
    ans(rest)   


    uri_to_localpath("${uri}")
    ans(command)
    
    set(args)
    while(true)
      string_take_commandline_arg(rest)
      ans(arg)
      string_decode_delimited("${arg}")
      ans(arg)

      list(APPEND args "${arg}")
      if("${arg}_" STREQUAL "_")
        break()
      endif()
    endwhile()

    map_capture_new(command args)
    return_ans()
  endfunction()




function(command_line_to_string)
    command_line(${ARGN})
    ans(cmd)

    scope_import_map(${cmd})

    command_line_args_combine(${args})
    ans(arg_string)
    if(NOT "${arg_string}_" STREQUAL "_")
      set(arg_string " ${arg_string}")
    endif()
    set(command_line "${command}${arg_string}")
    return_ref(command_line)
  endfunction()


  




## `(<process start info> [--process-handle] [--exit-code] [--async] [--silent-fail] [--success-callback <callable>]  [--error-callback <callable>] [--state-changed-callback <callable>])-><process handle>|<exit code>|<stdout>|<null>`
##
## *options*
## * `--process-handle` 
## * `--exit-code` 
## * `--async` 
## * `--silent-fail` 
## * `--success-callback <callable>[exit_code](<process handle>)` 
## * `--error-callback <callable>[exit_code](<process handle>)` 
## * `--state-changed-callback <callable>[old_state;new_state](<process handle>)` 
## * `--lean`
## *example*
## ```
##  execute(cmake -E echo_append hello) -> '@execute(cmake -E echo_append hello)'
## ```
function(execute)
  set(args ${ARGN})
  list_extract_flag(args --lean)
  ans(lean)


  arguments_encoded_list(${ARGC})
  ans(args)

  list_extract_flag(args --process-handle)
  ans(return_handle)
  list_extract_flag(args --exit-code)
  ans(return_exit_code)
  list_extract_flag(args --async)
  ans(async)
  #list_extract_flag(args --async-wait)
  #ans(wait)
  #if(wait)
  #  set(async true)
  #endif()
  list_extract_flag(args --silent-fail)
  ans(silent_fail)

  list_extract_labelled_value(args --success-callback)
  ans(success_callback)
  list_extract_labelled_value(args --error-callback)
  ans(error_callback)
  list_extract_labelled_value(args --state-changed-callback)
  ans(process_callback)
  list_extract_labelled_value(args --on-terminated-callback)
  ans(terminated_callback)
  if(NOT args)
    messagE(FATAL_ERROR "no command specified")
  endif()

  process_start_info_new(${args})
  ans(start_info)

##debug here
  #print_vars(start_info.command start_info.command_arguments)

  process_handle_new(${start_info})
  ans(process_handle)

  if(success_callback)
    string_decode_list("${success_callback}")
    ans(success_callback)
    assign(success = process_handle.on_success.add("${success_callback}"))
  endif()
  if(error_callback)
    string_decode_list("${error_callback}")
    ans(error_callback)
    assign(success = process_handle.on_error.add("${error_callback}"))
  endif()
  if(process_callback)
    string_decode_list("${process_callback}")
    ans(process_callback)
    assign(success = process_handle.on_state_change.add("${process_callback}"))
  endif()
  if(terminated_callback)
    string_decode_list("${terminated_callback}")
    ans(terminated_callback)
    assign(success = process_handle.on_terminated.add("${terminated_callback}"))
  endif()

  if(async)
    process_start(${process_handle})
    return(${process_handle})
  else()
    process_execute(${process_handle})
    if(return_handle)
      return(${process_handle})
    endif()


    
    map_tryget(${process_handle} exit_code)
    ans(exit_code)

    if(return_exit_code)
      return_ref(exit_code)
    endif()

    map_tryget(${process_handle} pid)
    ans(pid)
    if(NOT pid)
      message(FATAL_ERROR FORMAT "could not find command '{start_info.command}'")
    endif()

    if(exit_code AND silent_fail)
      error("process {start_info.command} failed with {process_handle.exit_code}")
      return()
    endif()

    if(exit_code)
      message(FATAL_ERROR FORMAT "process {start_info.command} failed with {process_handle.exit_code}")
    endif()


    map_tryget(${process_handle} stdout)
    ans(stdout)
    return_ref(stdout)

  endif()


endfunction()




## `(<cmake code> [--pure] <args...>)-><execute result>`
##
## equivalent to `execute(...)->...` runs the specified code using `cmake -P`.  
## prepends the current `cmakepp.cmake` to the script  (this default behaviour can be stopped by adding `--pure`)
##
## all not specified `args` are forwarded to `execute`
##
function(execute_script script)
  set(args ${ARGN})

  list_extract_flag(args --no-cmakepp)
  ans(nocmakepp)

  if(NOT nocmakepp)
    cmakepp_config(cmakepp_path)
    ans(cmakepp_path)
    set(script "include(\"${cmakepp_path}\")\n${script}")
  endif()
  fwrite_temp("${script}" ".cmake")
  ans(script_file)
  ## execute add callback to delete temporary file
  execute("${CMAKE_COMMAND}" -P "${script_file}"  --on-terminated-callback "[]() rm(${script_file})" ${args}) 
  return_ans()
endfunction()






# wraps the bash executable in cmake
function(bash)
  wrap_executable(bash bash)
  bash(${ARGN})
  return_ans()
endfunction()







function(bash_lean)
  wrap_executable_bare(bash_lean bash)
  bash_lean(${ARGN})
  return_ans()
endfunction()






  ## wraps the linux pkill command
  function(linux_kill)
    wrap_executable(linux_kill kill)
    linux_kill(${ARGN})
    return_ans()
  endfunction()





# wraps the linux ps command into an executable 
function(linux_ps)
  wrap_executable(linux_ps ps)
  linux_ps(${ARGN})
  return_ans()
endfunction()





function(linux_ps_info pid key)
  linux_ps_lean(-p "${pid}" -o "${key}=")
  ans_extract(error)
  ans(stdout)
  #print_vars(error stdout)

  if(error)
    return()
  endif()
  string(STRIP "${stdout}" val)
  return_ref(val)
endfunction()






function(linux_ps_info_capture pid map)

  foreach(key ${ARGN})
    linux_ps_info("${pid}" "${key}")
    ans(val)
    map_set(${map} "${key}" "${val}")

  endforeach()
  return()
endfunction()






function(linux_ps_info_get pid)
  map_new()
  ans(map)
  linux_ps_info_capture("${pid}" "${map}" ${ARGN})
  return("${map}")

endfunction()






function(linux_ps_lean)
  wrap_executable_bare(linux_ps_lean ps)
  linux_ps_lean(${ARGN})
  return_ans()
endfunction()




function(nohup)
    wrap_executable(nohup nohup)
    nohup(${ARGN})
    return_ans()
endfunction()




## process_info implementation for linux_ps
## currently only returns the process command name
function(process_info_Linux handle)
  process_handle("${handle}")
  ans(handle)

  map_tryget(${handle} pid)
  ans(pid)
  

  linux_ps_info_capture(${pid} ${handle} comm)


  return_ref(handle)    
endfunction()







function(process_isrunning_Linux handle)
  process_handle("${handle}")
  ans(handle)
  map_tryget(${handle} pid)
  ans(pid)
  linux_ps_info(${pid} pid)
  ans(val)
  if(NOT "${val}_" STREQUAL "${pid}_")
    return(false)
  endif()
  return(true)
endfunction()






  ## platform specific implementaiton for process_kill
  function(process_kill_Linux handle)
    process_handle("${handle}")
    ans(handle)

    map_tryget(${handle} pid)
    ans(pid)

    linux_kill(-SIGTERM ${pid} --exit-code)
    ans(error)

    return_truth("${error}" EQUAL 0)
  endfunction() 




# linux specific implementation of process_list 
# returns a list of <process handle> which only contains pid


  function(process_list_Linux)

    linux_ps_lean()
    ans_extract(error)
    ans(res)

   # print_vars(error res)

    string_lines("${res}")
    ans(lines)

    list_pop_front(lines)
    ans(headers)

    set(handles)
    set(ps_regex " *([1-9][0-9]*)[ ]*")
    #set(ps_regex " *([1-9][0-9]*)[ ]*([^ ]+)[ ]*([0-9][0-9]):([0-9][0-9]):([0-9][0-9]) *([^ ].*)")
    foreach(line ${lines})
      string(REGEX REPLACE "${ps_regex}" "\\1" pid "${line}")
      #string(REGEX REPLACE "${ps_regex}" "\\2" tty "${line}")
      #string(REGEX REPLACE "${ps_regex}" "\\3" hh "${line}")
      #string(REGEX REPLACE "${ps_regex}" "\\4" mm "${line}")
      #string(REGEX REPLACE "${ps_regex}" "\\5" ss "${line}")
      #string(REGEX REPLACE "${ps_regex}" "\\6" cmd "${line}")
      #string(STRIP "${cmd}" cmd)

      process_handle("${pid}")
      ans(handle)
      #map_capture(${handle} tty hh mm ss cmd) 
      
      list(APPEND handles ${handle})
    endforeach()
    return_ref(handles)
  endfunction()






# process_fork implementation specific to linux
# uses bash and nohup to start a process 
function(process_start_Linux process_handle)
  process_handle_register(${process_handle})
  map_tryget(${process_handle} start_info)

  ans(process_start_info)

  map_tryget(${process_start_info} command)
  ans(command)

  map_tryget(${process_start_info} command_arguments)
  ans(command_arguments)

  map_tryget(${process_start_info} working_directory)
  ans(working_directory)

  command_line_args_combine(${command_arguments})
  ans(command_arguments_string)

  set(command_string "${command} ${command_arguments_string}")

  # define output files        
  fwrite_temp("")
  ans(stdout)
  fwrite_temp("")
  ans(stderr)
  fwrite_temp("")
  ans(return_code)
  fwrite_temp("")
  ans(pid_out)

  process_handle_change_state(${process_handle} starting)
  # create a temporary shell script 
  # which starts bash with the specified command 
  # output of the command is stored in stdout file 
  # error of the command is stored in stderr file 
  # return_code is stored in return_code file 
  # and the created process id is stored in pid_out
  shell_tmp_script("( bash -c \"(cd ${working_directory}; ${command_string} > ${stdout} 2> ${stderr})\" ; echo $? > ${return_code}) & echo $! > ${pid_out}")
  ans(script)
  ## execute the script in bash with nohup 
  ## which causes the script to run detached from process
  bash_lean(-c "nohup ${script} > /dev/null 2> /dev/null")
  ans(error)

  if(error)
    message(FATAL_ERROR "could not start process '${command_string}'")
  endif()



  fread("${pid_out}")
  ans(pid)

  string(STRIP "${pid}" pid)

  map_set(${process_handle} pid "${pid}")

  process_handle_change_state(${process_handle} running)


  ## set output of process
  map_set(${process_handle} stdout_file ${stdout})
  map_set(${process_handle} stderr_file ${stderr})
  map_set(${process_handle} return_code_file ${return_code})
  

  process_refresh_handle("${process_handle}")

  return_ref(process_handle)
endfunction()





## `(<process handle>)-><process handle>`
##
## executes the specified command with the specified arguments in the 
## current working directory
## creates and registers a process handle which is then returned 
## this function accepts arguments as encoded lists. this allows you to include
## arguments which contain semicolon and other special string chars. 
## the process id of processes start with `process_execute` is always -1
## because `CMake`'s `execute_process` does not return it. This is not too much of a problem
## because the process will always be terminated as soon as the function returns
## 
## **parameters**
##   * `<command>` the executable (may contain spaces) 
##   * `<arg...>` the arguments - may be an encoded list 
## **scope**
##   * `pwd()` used as the working-directory
## **events** 
##   * `on_process_handle_created` global event is emitted when the process_handle is ready
##   * `process_handle.on_state_changed`
##
## **returns**
## ```
## <process handle> ::= {
##   pid: "-1"|"0"
##     
## }
## ``` 
function(process_execute process_handle)
  process_handle_register(${process_handle})

  map_tryget(${process_handle} start_info)
  ans(process_start_info)  

  ## the pid is -1 by default for non async processes
  map_set(${process_handle} pid -1)

  ## register process handle
  process_handle_change_state(${process_handle} starting)
  process_handle_change_state(${process_handle} running)

  map_tryget(${process_start_info} working_directory)
  ans(cwd)

  map_tryget(${process_start_info} command)
  ans(command)

  cmake_string_escape("${command}")
  ans(command)

  map_tryget(${process_start_info} command_arguments)
  ans(command_arguments)


  #command_line_args_combine(${command_arguments})
  #ans(command_arguments_string)

  set(command_arguments_string)
  foreach(argument ${command_arguments})
    string_decode_list("${argument}")
    ans(argument)
    cmake_string_escape("${argument}")
    ans(argument)
    set(command_arguments_string "${command_arguments_string} ${argument}")
  endforeach()
  

  map_tryget(${process_start_info} timeout)
  ans(timeout)


  if("${timeout}" GREATER -1)
    set(timeout TIMEOUT ${timeout})
  else()
    set(timeout)
  endif()

  #message("executing ${command} ${command_arguments_string}")

  set(eval_this "
    execute_process(
      COMMAND ${command} ${command_arguments_string}
      RESULT_VARIABLE exit_code
      OUTPUT_VARIABLE stdout
      ERROR_VARIABLE stderr
      WORKING_DIRECTORY ${cwd}
      ${timeout}
    )
  ")
#  _message("${eval_this}")
  eval_ref(eval_this)

  ## set process handle variables
  if(NOT "${exit_code}" MATCHES "^-?[0-9]+$")
    map_set(${process_handle} pid)
  endif()
  map_set(${process_handle} exit_code "${exit_code}")
  map_set(${process_handle} stdout "${stdout}")
  map_set(${process_handle} stderr "${stderr}")

  ## change state
  process_handle_change_state(${process_handle} terminated)

  return_ref(process_handle)
endfunction()





## returns the runtime unique process handle
## information may differ depending on os but the following are the same for any os
## * pid
## * status
function(process_handle handlish)
  is_map("${handlish}")
  ans(ismap)

  if(ismap)
    set(handle ${handlish})
  elseif( "${handlish}" MATCHES "[0-9]+")
    string(REGEX MATCH "[0-9]+" handlish "${handlish}")

    map_tryget(__process_handles ${handlish})
    ans(handle)
    if(NOT handle)
      map_new()
      ans(handle)
      map_set(${handle} pid "${handlish}")          
      map_set(${handle} state "unknown")
      map_set(__process_handles ${handlish} ${handle})
    endif()
  else()
    message(FATAL_ERROR "'${handlish}' is not a valid <process handle>")
  endif()
  return_ref(handle)
endfunction()





## transforms a list of <process handle?!> into a list of <process handle>  
function(process_handles)
  set(handles)
  foreach(arg ${ARGN})
    process_handle("${arg}")
    ans(handle)
    list(APPEND handles ${handle})
  endforeach()
  return_ref(handles)
endfunction()





function(process_handle_change_state process_handle new_state)
  map_tryget("${process_handle}" state)
  ans(old_state)
  if("${old_state}" STREQUAL "${new_state}")
    return(false)
  endif()

  map_tryget(${process_handle} on_state_change)
  ans(on_state_change_event)

  event_emit(${on_state_change_event} ${process_handle})



  map_set(${process_handle} state "${new_state}")

  if("${new_state}" STREQUAL "terminated")
    map_tryget(${process_handle} exit_code)
    ans(error)
    if(error)
      map_tryget("${process_handle}" on_error)
      ans(on_error_event)
      event_emit("${on_error_event}" ${process_handle})  
    else()
      map_tryget("${process_handle}" on_success)
      ans(on_success_event)
      event_emit("${on_success_event}" ${process_handle})  
    endif()
    map_tryget("${process_handle}" on_terminated)
    ans(on_terminated_event)
    event_emit("${on_terminated_event}" ${process_handle})
endif()

  return(true)
endfunction()





function(process_handle_get pid)
  map_tryget(__process_handles ${pid})
  return_ans()
endfunction()




## `(<process start info>)-><process handle>`
##
## returns a new process handle which has the following layout:
## ```
## <process handle> ::= {
##   pid: <pid>  
##   start_info: <process start info>
##   state: "unknown"|"running"|"terminated"
##   stdout: <text>
##   stderr: <text>
##   exit_code: <integer>|<error string>
##   command: <executable>
##   command_args: <encoded list>
##   on_state_change: <event>[old_state, new_state](${process_handle}) 
## }
## ``` 
function(process_handle_new start_info)
  map_new()
  ans(process_handle)
  map_set(${process_handle} pid "")
  map_set(${process_handle} start_info "${start_info}")
  map_set(${process_handle} state "unknown")
  map_set(${process_handle} stdout "")
  map_set(${process_handle} stderr "")
  map_set(${process_handle} exit_code)
  event_new()
  ans(event)
  map_set(${process_handle} on_state_change ${event})

  event_new()
  ans(event)
  map_set(${process_handle} on_success ${event})


  event_new()
  ans(event)
  map_set(${process_handle} on_error ${event})


  event_new()
  ans(event)
  map_set(${process_handle} on_terminated ${event})

  return_ref(process_handle)
endfunction()






function(process_handle_register process_handle)
  event_emit(on_process_handle_created ${process_handle})
endfunction()





## process_info(<process handle?!>): <process info>
## returns information on the specified process handle
function(process_info)
  wrap_platform_specific_function(process_info)
  process_info(${ARGN})
  ans(res)
  return_ref(res)
endfunction()





## returns true iff the process identified by <handlish> is running
function(process_isrunning)    
  wrap_platform_specific_function(process_isrunning)    
  process_isrunning(${ARGN})
  return_ans()
endfunction()






# process_kill(<process handle?!>)
# stops the process specified by <process handle?!>
# returns true if the process was killed successfully
function(process_kill)
  wrap_platform_specific_function(process_kill)
  process_kill(${ARGN})
  return_ans()
endfunction()





## returns a list of <process info> containing all processes currently running on os
## process_list():<process info>...
function(process_list)
  wrap_platform_specific_function(process_list)
  process_list(${ARGN})
  return_ans()
endfunction()





## refreshes the fields of the process handle
## returns true if the process is still running false otherwise
## this is the only function which is allowed to change the state of a process handle
function(process_refresh_handle handle)
  process_handle("${handle}")
  ans(handle)


  process_isrunning("${handle}")
  ans(isrunning)

  if(isrunning)
    set(state running)
  else()
    set(state terminated)
  endif()

  if("${state}" STREQUAL "terminated")
    process_return_code("${handle}")
    ans(exit_code)
    process_stdout("${handle}")
    ans(stdout)
    process_stderr("${handle}")
    ans(stderr)
    map_capture("${handle}" exit_code stdout stderr)
  endif()


  process_handle_change_state("${handle}" "${state}")
  ans(state_changed)

  




  return_ref(isrunning)

endfunction()





## returns the <return_code> for the specified process handle
## if process is not finished the result is empty
  function(process_return_code handle)
    process_handle("${handle}")
    ans(handle)
    map_tryget("${handle}" return_code_file)
    ans(return_code_file)
    fread("${return_code_file}")
    ans(return_code)
    string(STRIP "${return_code}" return_code)
    return_ref(return_code)
  endfunction()





## starts a process and returns a handle which can be used to controll it.  
##
# {
#   <pid:<unique identifier>> // some sort of unique identifier which can be used to identify the processs
#   <process_start_info:<process start info>> /// the start info for the process
#   <output:<function():<string>>>
#   <status:"running"|"complete"> // indicates weather the process is complete - this is a cached result because query the process state is expensive
# }
function(process_start)
  wrap_platform_specific_function(process_start)
  process_start(${ARGN})
  return_ans()
endfunction()












## `(<command string>|<object>)-><process start info>` 
## `<command string> ::= "COMMAND"? <command> <arg...>` 
##
## creates a new process_start_info with the following fields
## ```
## <process start info> ::= {
##   command: <executable> 
##   command_arguments: <encoded list>
##   working_directory: <directory>
##   timeout: <n>
## }
## ```
##
## *example*
##  * `process_start_info_new(COMMAND cmake -E echo "asd bsd" csd) -> <% process_start_info_new(COMMAND cmake -E echo "asd;bsd")
##  ans(info)
##  template_out_json(${info}) %>` 
function(process_start_info_new)
  arguments_encoded_list(${ARGC})
  ans(arguments_list)

  list_extract_any_labelled_value(arguments_list WORKING_DIRECTORY)
  ans(working_directory)
  list_extract_any_labelled_value(arguments_list TIMEOUT)
  ans(timeout)

  if(NOT timeout)
    set(timeout -1)
  endif()

  path_qualify(working_directory)

  list_pop_front(arguments_list)
  ans(command)

  if("${command}_" STREQUAL "COMMAND_")
    list_pop_front(arguments_list)
    ans(command)
  endif()

  string_decode_list("${command}")
  ans(command)

  map_new()
  ans(process_start_info)
  map_set(${process_start_info} command "${command}")  
  map_set(${process_start_info} command_arguments "${arguments_list}")
  map_set(${process_start_info} working_directory "${working_directory}")  
  map_set(${process_start_info} timeout "${timeout}")

  return_ref(process_start_info)
endfunction()





## shorthand to fork a cmake script
function(process_start_script scriptish)
  fwrite_temp("${scriptish}" ".cmake")
  ans(script_path)
  execute(
    COMMAND
    "${CMAKE_COMMAND}"
    -P
    "${script_path}"
    ${ARGN}
    --async
  )
  return_ans()
endfunction()




## returns the current error output
## This can change until the process is finished
function(process_stderr handle)
    process_handle("${handle}")
    ans(handle)
    map_tryget("${handle}" stderr_file)
    ans(stderr_file)
    fread("${stderr_file}")
    ans(stderr)
    return_ref(stderr)
endfunction()






## returns the current stdout of a <process handle>
## this changes until the process is ove
function(process_stdout handle)
    process_handle("${handle}")
    ans(handle)
    map_tryget("${handle}" stdout_file)
    ans(stdout_file)
    fread("${stdout_file}")
    ans(stdout)
return_ref(stdout)
endfunction()





## returns a <process handle> to a process that runs for n seconds
#todo create shims
function(process_timeout n)
  if(${CMAKE_MAJOR_VERSION} GREATER 2)
    execute(${CMAKE_COMMAND} -E sleep ${n} --async)
    return_ans()
  else()
    if(UNIX)
      execute(sleep ${n} --async)
      return_ans()
    endif()
  endif()
endfunction()





  ## blocks until given process has terminated
  ## returns nothing if the process does not exist - is deleted etc
  ## updates and returns the process_handle
  ## if a timeout greater 0 the function will return nothing if the timeout is reached
  ## process_wait(<process handle> <?--timeout:<seconds>>)
  function(process_wait handle)
    process_handle("${handle}")
    ans(handle)

    set(args ${ARGN})
    list_extract_labelled_value(args --timeout)
    ans(timeout)

    if("${timeout}_" STREQUAL "_")
      set(timeout -1)
    endif()

    if("${timeout}" LESS 0)
      while(true)

        process_refresh_handle(${handle})
        ans(isrunning)
        if(NOT isrunning)
          return(${handle})
        endif()
      endwhile()
    elseif("${timeout}" EQUAL 0)
      process_refresh_handle(${handle})
      ans(isrunning)
      if(isrunning)
        return()
      else()
        return("${handle}")
      endif()
    else()
      process_timeout(${timeout})
      ans(timeout_handle)
      while(true)
        process_refresh_handle(${handle})
        ans(isrunning)
        if(NOT isrunning)
          process_kill(${timeout_handle})
          return(${handle})
        endif()
        process_refresh_handle(${timeout_handle})
        ans(isrunning)
        if(NOT isrunning)
          return()
        endif()
      endwhile()
    endif()
endfunction()




## `(<handles: <process handle...>>  [--timeout <seconds>] [--idle-callback <callable>] [--task-complete-callback <callable>] )`
##
## waits for all specified <process handles> to finish returns them in the order
## in which they completed
##
## `--timeout <n>`    if value is specified the function will return all 
##                    finished processes after n seconds
##
## `--idle-callback <callable>`   
##                    if value is specified it will be called at least once
##                    and between every query if a task is still running 
##
##
## `--task-complete-callback <callable>`
##                    if value is specified it will be called whenever a 
##                    task completes.
##
## *Example*
## `process_wait_all(${handle1} ${handle1}  --task-complete-callback "[](handle)message(FORMAT '{handle.pid}')")`
## prints the process id to the console whenver a process finishes
##
function(process_wait_all)
  set(args ${ARGN})

  list_extract_labelled_value(args --idle-callback)
  ans(idle_callback)

  list_extract_labelled_value(args --task-complete-callback)
  ans(task_complete_callback)

  list_extract_labelled_value(args --timeout)
  ans(timeout)
  set(timeout_task_handle)


  process_handles(${args})
  ans(process_list)
  ans(running_processes)


  list(LENGTH running_processes process_count)

  set(timeout_process_handle)
  if(timeout)
    process_timeout(${timeout})
    ans(timeout_process_handle)
    list(APPEND running_processes ${timeout_process_handle})
  endif()
  set(complete_count 0)
  while(running_processes)

    list_pop_front(running_processes)
    ans(current_process)
    process_refresh_handle(${current_process})
    ans(is_running)
    
    #message(FORMAT "{current_process.pid} is_running {is_running} {current_process.state} ")

    if(NOT is_running)
      if("${current_process}_" STREQUAL "_${timeout_process_handle}")
        set(running_processes)
      else()          

        list(APPEND complete_processes ${current_process})          
        if(NOT quietly)
          list(LENGTH complete_processes complete_count)           
          if(task_complete_callback)
            call2("${task_complete_callback}" "${current_process}") 
          endif()
        endif() 
      endif()        
    else()
      ## insert into back
      list(APPEND running_processes ${current_process})
    endif()

    if(idle_callback)
      call2("${idle_callback}")
    endif()

  endwhile()

  return_ref(complete_processes)
endfunction()





  ## waits until any of the specified handles stops running
  ## returns the handle of that process
  ## if --timeout <n> is specified function will return nothing after n seconds
  function(process_wait_any)
    set(args ${ARGN})

    list_extract_flag(args --quietly)
    ans(quietly)    

    process_handles(${args})
    ans(processes)


    if(NOT quietly)
      list(LENGTH processes len)
      echo_append("waiting for any of ${len} processes to finish.")  
    endif()

    set(timeout_process_handle)
    if(timeout)
      process_timeout(${timeout})
      ans(timeout_process_handle)
      list(APPEND processes ${timeout_process_handle})
    endif()

    while(processes)
      list_pop_front(processes)
      ans(process)
      process_refresh_handle(${process})
      ans(isrunning)


      if(NOT quietly)
        tick()
      endif()

      if(NOT isrunning)
        if("${process}_" STREQUAL "${timeout_process_handle}_")      
          echo(".. timeout")
          return()
        endif()
        if(NOT quietly)
          echo("")
        endif()
        return(${process})
      else()
        list(APPEND processes ${process})
      endif()

    endwhile()   
  endfunction()





## `(<n:<int>|"*"> <process handle>... [--idle-callback:<callable>])-><process handle>...`
##
## waits for at least <n> processes to complete 
##
## returns: 
##  * at least `n` terminated processes
## 
## arguments: 
## * `n` an integer the number of processes to return (lower bound) if `n` is clamped to the number of processes. if `n` is * it is replaced with the number of processes 
## * `--idle-callback` is called after every time a processes state was polled. It is guaranteed to be called once per process handle. it has access to the following scope variables
##    * `terminated_count` number of terminated processes
##    * `running_count` number of running processes
##    * `wait_time` time that was waited
##    * `wait_counter` number of times the waiting loop iterated
##    * `running_processes` list of running processes 
##    * `current_process` the current process being polled
##    * `is_running` the running state of the current process
##    * `terminated_processes` the list of terminated processes
##
function(process_wait_n n)
  arguments_extract_typed_values(0 ${ARGC}
    <n:<string>>
    [--idle-callback:<callable>] # 
    [--timeout:<int>?]
  )
  ans(process_handles)

  list(LENGTH process_handles process_count)

  set(running_processes ${process_handles})
  set(terminated_processes)

  timer_start(__process_wait_timer)
  set(wait_counter 0)
  
  if("${n}" STREQUAL "*")
    list(LENGTH running_processes n)
  endif()  

  set(terminated_count 0)

  set(wait_time)
  while(true)
    if(timeout)
      if(${timeout} GREATER ${wait_time})
        break()
      endif()
    endif()


    set(queue ${running_processes})

    while(queue)
      list_pop_front(queue)
      ans(current_process)
    

      process_refresh_handle(${current_process})
      ans(is_running)

      if(NOT is_running)
        list(REMOVE_ITEM running_processes ${current_process})
        list(APPEND terminated_processes ${current_process})
      endif()
      
      ## status vars
      timer_elapsed(__process_wait_timer)
      ans(wait_time)
      list(LENGTH terminated_processes terminated_count)
      list(LENGTH running_processes running_count)

      if(idle_callback)
        call2("${idle_callback}")
      endif()
      math(EXPR wait_counter "${wait_counter} + 1")

    endwhile()

    if(NOT ${terminated_count} LESS ${n})
      break()
    endif()
    if(NOT running_processes)
      return()
    endif()
  endwhile()


  return_ref(terminated_processes)
endfunction()





  function(string_take_commandline_arg str_ref)
    string_take_whitespace(${str_ref})
    set(regex "(\"([^\"\\\\]|\\\\.)*\")|[^ ]+")
    string_take_regex(${str_ref} "${regex}")
    ans(res)
    if(NOT "${res}_" STREQUAL _)
      set("${str_ref}" "${${str_ref}}" PARENT_SCOPE)
    endif()
    if("${res}" MATCHES "\".*\"")
      string_take_delimited(res "\"")
      ans(res)
    endif()

    return_ref(res)


  endfunction()





## windows specific implementation for process_info
function(process_info_Windows handlish)
  process_handle("${handlish}")
  ans(handle)
  map_tryget(${handle} pid)
  ans(pid)


  win32_tasklist(/V /FO CSV /FI "PID eq ${pid}" --process-handle )
  ans(exe_result)


  map_tryget(${exe_result} exit_code)
  ans(error)
  if(error)
    return()
  endif()


  map_tryget(${exe_result} stdout)
  ans(csv)


  csv_deserialize("${csv}" --headers)  
  ans(res)

  map_rename(${res} PID pid)
  return_ref(res)
endfunction()








## platform specific implementation for process_isrunning under windows
function(process_isrunning_Windows handlish)    
  process_handle("${handlish}")    
  ans(handle)    
  map_tryget(${handle} state)
  ans(state)
  if("${state}_" STREQUAL "terminated_" )
    return(false)
  endif()

  map_tryget(${handle} pid)
  ans(pid)
  
  win32_tasklist_bare(-FI "PID eq ${pid}" -FI "STATUS eq Running")
  ans_extract(error)
  ans(res)
  if("${res}" MATCHES "${pid}")
    return(true)
  endif()
  return(false)
endfunction()







# windows implementation for process kill
function(process_kill_Windows process_handle)
  process_handle("${process_handle}")
  map_tryget(${process_handle} pid)
  ans(pid)

  win32_taskkill(/PID ${pid} --exit-code)
  ans(exit_code)
  if(exit_code)
    return(false)
  endif()
  return(true)
endfunction()






## platform specific implementation for process_list under windows
function(process_list_Windows)
  win32_wmic(process where "processid > 0" get processid) #ignore idle process
  ans(ids)


  string(REGEX MATCHALL "[0-9]+" matches "${ids}")
  set(ids)



  foreach(id ${matches})
    process_handle("${id}")
    ans(handle)
    list(APPEND ids ${handle})
  endforeach()



  return_ref(ids)
endfunction()




## windows implementation for start process
## newer faster version
 function(process_start_Windows process_handle)
    ## create a process handle from pid
    process_handle_register(${process_handle})

    map_tryget(${process_handle} start_info)
    ans(start_info)


    map_tryget(${start_info} command)
    ans(command)

    map_tryget(${start_info} command_arguments)
    ans(command_arguments)

    command_line_args_combine(${command_arguments})
    ans(command_arguments_string)

    set(command_string "\"${command}\" ${command_arguments_string}")

    map_tryget(${start_info} working_directory)
    ans(working_directory)

    ## create temp dir where process specific files are stored
    mktemp()
    ans(dir)
    ## files where to store stdout and stderr
    set(outputfile "${dir}/stdout.txt")
    set(errorfile "${dir}/stderr.txt")
    set(returncodefile "${dir}/retcode.txt")
    set(pidfile "${dir}/pid.txt")

    fwrite("${outputfile}" "")
    fwrite("${errorfile}" "")
    fwrite("${returncodefile}" "")


    ## creates a temporary batch file
    ## which gets the process id (get the parent process id wmic....)
    ## output pid to file output command_string to 
    fwrite_temp("
      @echo off
      cd \"${working_directory}\"
      wmic process get parentprocessid,name|find \"WMIC\" > ${pidfile}
      ${command_string} > ${outputfile} 2> ${errorfile}
      echo %errorlevel% > ${returncodefile}
      exit
    " ".bat")
    ans(path)


    process_handle_change_state(${process_handle} starting)
    win32_powershell_lean("start-process -File ${path} -WindowStyle Hidden")


    ## wait until the pidfile exists and contains a valid pid
    ## this seems very hackisch but is necessary as i have not found
    ## a simpler way to do it
    while(true)
      if(EXISTS "${pidfile}")
        fread("${pidfile}")
        ans(pid)
        if("${pid}" MATCHES "[0-9]+" )
          set(pid "${CMAKE_MATCH_0}")
          break()
        endif()
      endif()
    endwhile()
    map_set(${process_handle} pid "${pid}")
    
    process_handle_change_state(${process_handle} running)

    
    ## set the output files for process_handle
    map_set(${process_handle} stdout_file ${outputfile})
    map_set(${process_handle} stderr_file ${errorfile})
    map_set(${process_handle} return_code_file  ${returncodefile})

    assign(!process_handle.windows.process_data_dir = dir) 

    return_ref(process_handle)
  endfunction()






# wrap_executable(<alias> <executable> <args...>)-><null>
#
# creates a function called ${alias} which wraps the executable specified in ${executable}
# <args...> will be set as command line arguments for every call
# the alias function's varargs will be passed on as command line arguments. 
#
# Warning: --async is a bit experimental
#
# defines function
# <alias>([--async]|[--process-handle]|[--exit-code])-> <stdout>|<process result>|<exit code>|<process handle>
#
# <no flag>       if no flag is specified then the function will fail if the return code is not 0
#                 if it succeeds the return value is the stdout
#
# --process-handle        flag the function will return a the execution 
#                 result object (see execute()) 
# --exit-code     flag the function will return the exit code
# --async         will execute the executable asynchroniously and
#                 return a <process handle>
# --async-wait    will execute the executable asynchroniously 
#                 but will not return until the task is finished
#                 printing a status indicator
# --lean          lean call to executable (little overhead - no events etc)
# 
# else only the application output will be returned 
# and if the application terminates with an exit code != 0 a fatal error will be raised
function(wrap_executable alias executable)
  arguments_encoded_list(${ARGC})
  ans(arguments)
  # remove alias and executable
  list_pop_front(arguments)
  list_pop_front(arguments)

  eval("  
    function(${alias})
      arguments_encoded_list(\${ARGC})
      ans(arguments)
      execute(\"${executable}\" ${arguments} \${arguments})
      return_ans()
    endfunction()
    ")
  return()
endfunction()





## a fast wrapper for the specified executable
## this should be used for executables that are called often
## and do not need to run async
function(wrap_executable_bare alias executable)

  eval("
    function(${alias})
      pwd()
      ans(cwd)
      #message(\"\${ARGN}\")
      execute_process(COMMAND \"${executable}\" ${ARGN} \${ARGN}
        WORKING_DIRECTORY  \"\${cwd}\"
        OUTPUT_VARIABLE stdout 
        ERROR_VARIABLE stdout 
        RESULT_VARIABLE error
      )
      list(INSERT stdout 0 \${error})
      return_ref(stdout)
    endfunction()
    ")
  return()
endfunction()





  function(propref_get_key)
    string_split_at_last(ref prop "${propref}" ".")
    return_ref(prop)
  endfunction()
  
 





  function(propref_get_ref)
    string_split_at_last(ref prop "${propref}" ".")
    return_ref(ref)
  endfunction()




 function(propis_address propref)
    string_split_at_last(ref prop "${propref}" ".")
    is_address("${ref}")
    ans(isref)
    if(NOT isref)
      return(false)
    endif()
    obj_has("${ref}" "${prop}")
    ans(has_prop)
    if(NOT has_prop)
      return(false)

    endif()
    return(true)
  endfunction()




function(end)
  # remove last key from key stack and last map from map stack
  # return the popped map
  stack_pop(:quick_map_key_stack)
  stack_pop(:quick_map_map_stack)
  return_ans()
endfunction()



## end() -> <current value>
##
## ends the current key, ref or map and returns the value
## 
function(end)
  stack_pop(quickmap)
  ans(ref)

  if(NOT ref)
    message(FATAL_ERROR "end() not possible ")
  endif()
    
  string_take_address(ref)
  ans(current_ref)

  return_ref(current_ref)
endfunction()





function(key key)
  # check if there is a current map
  stack_peek(:quick_map_map_stack)
  ans(current_map)
  if(NOT current_map)
    message(FATAL_ERROR "cannot set key for non existing map be sure to call first map() before first key()")
  endif()
  # set current key
  stack_pop(:quick_map_key_stack)
  stack_push(:quick_map_key_stack "${key}")
endfunction()


## key() -> <void>
##
## starts a new property for a map - may only be called
## after key or map
## fails if current ref is not a map
function(key key)
  stack_pop(quickmap)
  ans(current_key)

  string_take_address(current_key)
  ans(current_ref)
 
  #is_map("${current_ref}")
  is_address("${current_ref}")
  ans(ismap)
  if(NOT ismap)
    message(FATAL_ERROR "expected a map before key() call")
  endif()


  map_set("${current_ref}" "${key}" "")
  stack_push(quickmap "${current_ref}.${key}")
  return()
endfunction()





function(kv key)
  key("${key}")
  val(${ARGN})
endfunction()






function(map)
  set(key ${ARGN})

  # get current map
  stack_peek(:quick_map_map_stack)
  ans(current_map)

  # get current key
  stack_peek(:quick_map_key_stack)
  ans(current_key)

  if(ARGN)
    set(current_key ${ARGV0})
  endif()

  # create new current map
  map_new()
  ans(new_map)


  # add map to existing map
  if(current_map)
    key("${current_key}")
    val("${new_map}")
  endif()


  # push new map and new current key on stacks
  stack_push(:quick_map_map_stack ${new_map})
  stack_push(:quick_map_key_stack "")

  return_ref(new_map)
endfunction()



## map() -> <address>
## 
## begins a new map returning its address
## map needs to be ended via end()
function(map)
  if(NOT ARGN STREQUAL "")
    key("${ARGN}")
  endif()
  map_new()
  ans(ref)
  val(${ref})
  stack_push(quickmap ${ref})
  return_ref(ref)
endfunction()






## ref() -> <address> 
## 
## begins a new reference value and returns its address
## ref needs to be ended via end() call
function(ref)
  if(NOT ARGN STREQUAL "")
    key("${ARGN}")
  endif()
  address_new()
  ans(ref)
  val(${ref})
  stack_push(quickmap ${ref})   
  return_ref(ref)
endfunction()





function(val)
  # appends the values to the current_map[current_key]
  stack_peek(:quick_map_map_stack)
  ans(current_map)
  stack_peek(:quick_map_key_stack)
  ans(current_key)
  if(NOT current_map)
    set(res ${ARGN})
    return_ref(res)
  endif()
  map_append("${current_map}" "${current_key}" "${ARGN}")
endfunction()



## val(<val ...>) -> <any...>
##
## adds a val to current property or ref
##
function(val)
  set(args ${ARGN})
  stack_peek(quickmap)
  ans(current_ref)
  
  if(NOT current_ref)
    return()
  endif()
  ## todo check if map 
  address_append("${current_ref}" ${args})
  return_ref(args)
endfunction()






## captures a list of variable as a key value pair
function(var)
  foreach(var ${ARGN})
    kv("${var}" "${${var}}")
  endforeach()
endfunction()




function(address_append ref)
	set_property( GLOBAL APPEND PROPERTY "${ref}" "${ARGN}")
endfunction()




function(address_append_string ref str)
  set_property(GLOBAL APPEND_STRING PROPERTY "${ref}" "${str}")
endfunction()




function(address_delete ref)
	set_property(GLOBAL PROPERTY "${ref}")
endfunction()





function(address_get ref )
	get_property(ref_value GLOBAL PROPERTY "${ref}")
  return_ref(ref_value)
endfunction()

# optimized version
macro(address_get ref)
  get_property(__ans GLOBAL PROPERTY "${ref}")
endmacro()




function(address_new)
	address_set(":0" 0)
	
	function(address_new)
		address_get(":0" )
		ans(index)
		math(EXPR index "${index} + 1")
		address_set(":0" "${index}")
		if(ARGN)
		#	set(type "${ARGV0}")
			address_set(":${index}.__type__" "${ARGV0}")
		endif()
		return(":${index}")
	endfunction()

	address_new(${ARGN})
	return_ans()
endfunction()

## optimized version
function(address_new)
	set_property(GLOBAL PROPERTY ":0" 0 )
	function(address_new)
		get_property(index GLOBAL PROPERTY ":0")
		math(EXPR index "${index} + 1")
		set_property(GLOBAL PROPERTY ":0" ${index} )
		if(ARGN)
			set_property(GLOBAL PROPERTY ":${index}.__type__" "${ARGV0}")
		endif()
		set(__ans ":${index}" PARENT_SCOPE)
	endfunction()

	address_new(${ARGN})
	return_ans()
endfunction()





function(address_peek_back ref)
  address_get(${ref})
  ans(value)
  list_peek_back(value ${ARGN})
  ans(res)
  return_ref(res)
endfunction()





function(address_peek_front ref)
  address_get(${ref})
  ans(value)
  list_peek_front(value ${ARGN})
  ans(res)
  return_ref(res)
endfunction()





function(address_pop_back ref)
  address_get(${ref})
  ans(value)
  list_pop_back(value)
  ans(res)
  address_set(${ref} ${value})
  return_ref(res)
endfunction()





function(address_pop_front ref)
  address_get(${ref})
  ans(value)
  list_pop_front(value)
  ans(res)
  address_set(${ref} ${value})
  return_ref(res)
endfunction()




function(address_print ref)
  address_get("${ref}")
  _message("${ref}")
endfunction()





  function(address_push_back ref)
    address_get(${ref})
    ans(value)
    list_push_back(value "${ARGN}")
    ans(res)
    address_set(${ref} ${value})
    return_ref(res)
  endfunction()





function(address_push_front ref)
    get_property(value GLOBAL PROPERTY "${ref}")
  set_property( GLOBAL PROPERTY "${ref}" "${ARGN}" "${value}")
endfunction()




function(address_set ref)
	set_property(GLOBAL PROPERTY "${ref}" "${ARGN}")
endfunction()





function(address_set_new)
	address_new()
  ans(res)
	address_set(${res} "${ARGN}")
  return(${res})
endfunction()




function(address_type_get ref)
	is_address(${ref})
  ans(is_ref)
	if(NOT is_ref)
		return()
	endif()
	address_get("${ref}.__type__")
  ans(type)
	return_ref(type)
endfunction()




function(address_type_matches ref expectedType)
	is_address(${ref})
	ans(isref)

	if(NOT isref)
		return(false)
	endif()
	
	address_type_get(${ref})
  ans(type)
	if(NOT "${type}" STREQUAL "${expectedType}" )
		return(false)
	endif()
	return(true)
endfunction()




function(is_address ref)
  list(LENGTH ref len)
  if(NOT ${len} EQUAL 1)
    return(false)
  endif()
	string(REGEX MATCH "^:" res "${ref}" )
	if(res)
		return(true)
	endif()
	return(false)
endfunction()

## faster - does not work in all cases
macro(is_address ref)
  if("_${ref}" MATCHES "^_:[^;]+$")
    set(__ans true)
  else()  
    set(__ans false)
  endif()
endmacro()


## correcter
## the version above cannot be used because 
## is_address gets arbirtray data - and since macros evaluate 
## arguments a invalid ref could be ssen as valid 
## or especially \\ fails because it beomes \ and causes an error
function(is_address ref)
  if("_${ref}" MATCHES "^_:[^;]+$")
    set(__ans true PARENT_SCOPE)
  else()  
    set(__ans false PARENT_SCOPE)
  endif()
endfunction()






  ## access to the windows reg command
  function(reg)
    if(NOT WIN32)
      message(FATAL_ERROR "reg is not supported on non-windows platforms")
    endif()
    wrap_executable("reg" "REG")
    reg(${ARGN})
    return_ans()
  endfunction()

  function(reg_lean)

    if(NOT WIN32)
      message(FATAL_ERROR "reg is not supported on non-windows platforms")
    endif()
    wrap_executable_bare("reg_lean" "REG")
    reg_lean(${ARGN})
    return_ans()
  endfunction()





  ## appends all specified values to registry value if they are not contained already
  function(reg_append_if_not_exists key value_name)
    reg_read_value("${key}" "${value_name}")
    ans(values)
    set(added_values)
    foreach(arg ${ARGN})
      list_contains(values "${arg}")
      ans(res)
      if(NOT res) 
        list(APPEND values "${arg}")
        list(APPEND added_values "${arg}")
      endif()
    endforeach()

    string_decode_semicolon("${values}")
    ans(values)
    reg_write_value("${key}" "${value_name}" "${values}")
    return_ref(added_values)
  endfunction()








  ## appends a value to the specified windows registry value
  function(reg_append_value key value_name)
    reg_read_value("${key}" "${value_name}")
    ans(data)
    set(data "${data};${ARGN}")
    reg_write_value("${key}" "${value_name}" "${data}")
    return_ref(data)
  endfunction()






  ### returns true if the registry value contains the specified value
  function(reg_contains_value key value_name value)
    reg_read_value("${key}" "${value_name}")
    ans(values)
    list_contains(values "${value}")
    return_ans()
  endfunction()








  ## removes the specified value from the windows registry
  function(reg_delete_value key valueName)
    string(REPLACE / \\ key "${key}")
    reg(delete "${key}" /v "${valueName}" /f --exit-code)
    ans(error)
    if(error)
      return(false)
    else()
      return(true)
    endif()
  endfunction()







  ## parses the result of reg(query )call
  ## returns an reg entry object:
  ## {
  ##   "value_name":registry value name
  ##   "key":registry key
  ##   "value":value of the entry if it exists
  ##   "type": registry value type (ie REG_SZ) or KEY if its a key
  ## }
  function(reg_entry_parse query line)
      if("${line}" MATCHES "^    ([^ ]+)")
        set(regex "^    ([^ ]+)    ([^ ]+)    (.*)")
        string(REGEX REPLACE "${regex}" "\\1" value_name "${line}")
        string(REGEX REPLACE "${regex}" "\\2" type "${line}")
        string(REGEX REPLACE "${regex}" "\\3" value "${line}")
        string_decode_semicolon("${value}")
        ans(value)
        
      else()
   # _message("line ${line}")
        set(key "${line}")
        set(type "KEY")
        set(value "")
        set(value_name "")
      endif()
      map_capture_new(key value_name type value)
      return_ans()
  endfunction()






  ## prepends a value to the specified windows registry value
  function(reg_prepend_value key value_name)
    reg_read_value("${key}" "${value_name}")
    ans(data)
    set(data "${ARGN};${data}")
    reg_write_value("${key}" "${value_name}" "${data}")
    return_ref(data)
  endfunction()







  ## queryies the registry for the specified key
  ## returns a list of entries containing all direct child elements
  function(reg_query key)
    string(REPLACE / \\ key "${key}")
    reg(query "${key}" --process-handle)
    ans(res)

    map_tryget(${res} stdout)
    ans(output)


    map_tryget(${res} exit_code)
    ans(error)

    if(error)
      return()
    endif()
    
    string_encode_semicolon("${output}")
    ans(output)
    string(REPLACE "\n" ";" lines ${output})

    set(entries)
    foreach(line ${lines})
      reg_entry_parse("${key}" "${line}")
      ans(res)
      if(res)
        list(APPEND entries ${res})
      endif()
    endforeach()

    return_ref(entries)
  endfunction()






  ## returns a map contains all the values in the specified registry key
  function(reg_query_values key)
    reg_query("${key}")
    ans(entries)
    map_new()
    ans(res)
    foreach(entry ${entries})
      scope_import_map(${entry})
      if(NOT "${value}_" STREQUAL "_")        
        map_set("${res}" "${value_name}" "${value}")
      endif()
    endforeach()
    return_ref(res)
  endfunction()






  ## reads the specified value from the windows registry  
  function(reg_read_value key value_name)
    reg_query_values("${key}")
    ans(res)
    map_tryget(${res} "${value_name}")
    ans(res)
    
    return_ref(res)
  endfunction()







  ## removes all duplicat values form the specified registry value
  function(reg_remove_duplicate_values key value_name)
    reg_read_value("${key}" "${value_name}")
    ans(values)
    list(REMOVE_DUPLICATES values)
    reg_write_value("${key}" "${value_name}" "${values}")
    return()
  endfunction()






  ## removes the specified value from the registry value
function(reg_remove_value key value_name)
  reg_read_value("${key}" "${value_name}")
  ans(values)

  list_remove(values ${ARGN})
  reg_write_value("${key}" "${value_name}" "${values}")

  return()

endfunction()





  ## sets the specified windows registry value 
  ## value may contain semicolons
  function(reg_write_value key value_name value)
    string_encode_semicolon("${value}")
    ans(value)
    string(REPLACE / \\ key "${key}")
    set(type REG_SZ)
    reg(add "${key}" /v "${value_name}" /t "${type}" /f /d "${value}" --exit-code)
    ans(error)
    if(error)
      return(false)
    endif()
    return(true)
  endfunction()









  function(regex_all regex)
    string(REGEX MATCHALL "${regex}" ans ${ARGN})
    return_ref(ans)
  endfunction()




macro(regex_cmake)
  if(NOT __regex_cmake_included)
    set(__regex_cmake_included true)
  string_codes()

#http://www.cmake.org/cmake/help/v3.0/manual/cmake-language.7.html#grammar-token-regex_cmake_escape_sequence
  
  ## characters
  set(regex_cmake_newline "\n")
  set(regex_cmake_space_chars " \t")
  set(regex_cmake_space "[${regex_cmake_space_chars}]+")
  set(regex_cmake_backslash "\\\\")




  ## tokens

  # line comment
  set(regex_cmake_line_comment "#([^${regex_cmake_newline}]*)")
  set(regex_cmake_line_comment.comment CMAKE_MATCH_1)
  set(regex_cmake_line_comment_no_group "#([^${regex_cmake_newline}]*)")
  
  # bracket_comment
  set(regex_cmake_bracket_comment "#\\[\\[(.*)\\]\\]")
  set(regex_cmake_bracket_comment_no_group "#${bracket_open_code}${bracket_open_code}.*${bracket_close_code}${bracket_close_code}")
 
  # identifier
  set(regex_cmake_identifier "[A-Za-z_][A-Za-z0-9_]*")
  
  # nesting
  set(regex_cmake_nesting_start_char "\\(")
  set(regex_cmake_nesting_end_char "\\)")

  # quoted_argment
  set(regex_quoted_argument "\"([^\"\\]|([\\][\"])|([\\][\\])|([\\]))*\"")
  
  # unquoted_argument
  set(regex_unquoted_argument "[^#\\\\\" \t\n\\(\\)]+")



  ## combinations

  # matches every cmake token in a string
  set(regex_cmake_token "(${regex_cmake_bracket_comment_no_group})|(${regex_cmake_line_comment_no_group})|(${regex_quoted_argument})|${regex_unquoted_argument}|${regex_cmake_space}|${regex_cmake_newline}|${regex_cmake_nesting_start_char}|${regex_cmake_nesting_end_char}")


  set(regex_cmake_line_ending "(${regex_cmake_line_comment})?(${regex_cmake_newline})")   
  set(regex_cmake_separation "(${regex_cmake_space})|(${regex_cmake_line_ending})")

  
  ## misc

  # if a value matches this it needs to be put in quotes
  set(regex_cmake_value_needs_quotes "[ \";\\(\\)]")

  set(regex_cmake_value_quote_escape_chars "[\\\\\"]")


  set(regex_cmake_flag "-?-?[A-Za-z_][A-Za-z0-9_\\-]*")
  set(regex_cmake_double_dash_flag "\\-\\-[a-zA-Z0-9][a-zA-Z0-9\\-]*")
  set(regex_cmake_single_dash_flag "\\-[a-zA-Z0-9][a-zA-Z0-9\\-]*")
  
## todo: quoted, unquoated, etc
  set(regex_cmake_argument_string ".*")
  set(regex_cmake_command_invocation "(${regex_cmake_space})*(${regex_cmake_identifier})(${regex_cmake_space})*\\((${regex_cmake_argument_string})\\)")
  set(regex_cmake_command_invocation.regex_cmake_identifier CMAKE_MATCH_2)
  set(regex_cmake_command_invocation.arguments CMAKE_MATCH_4)



  set(regex_cmake_function_begin "(^|${cmake_regex_newline})(${regex_cmake_space})?function(${regex_cmake_space})?\\([^\\)\\(]*\\)")
  set(regex_cmake_function_end   "(^|${cmake_regex_newline})(${regex_cmake_space})?endfunction(${regex_cmake_space})?\\(([^\\)\\(]*)\\)")
  set(regex_cmake_function_signature "(^|${cmake_regex_newline})((${regex_cmake_space})?)(${regex_cmake_identifier})((${regex_cmake_space})?)\\([${regex_cmake_space_chars}${regex_cmake_newline}]*(${regex_cmake_identifier})(.*)\\)")
  set(regex_cmake_function_signature.name CMAKE_MATCH_7)
  set(regex_cmake_function_signature.args CMAKE_MATCH_8)
  
 

  endif()
  
endmacro()






## defines common regular expressions used in many places
macro(regex_common)

  set(regex_hex "[a-fA-F0-9]")
  set(regex_hex_2 "${regex_hex}${regex_hex}")
  set(regex_hex_4 "${regex_hex_2}${regex_hex_2}")
  set(regex_hex_8 "${regex_hex_4}${regex_hex_4}")
  set(regex_hex_12 "${regex_hex_8}${regex_hex_4}")

  set(regex_guid_ms "{(${regex_hex_8})\\-(${regex_hex_4})\\-(${regex_hex_4})\\-(${regex_hex_4})\\-(${regex_hex_12})}")



endmacro()





## returns the regex for a delimited string 
## allows escaping delimiter with '\' backslash
function(regex_delimited_string)
  set(delimiters ${ARGN})


  if("${delimiters}_" STREQUAL "_")
    set(delimiters \")
  endif()



  list_pop_front(delimiters)
  ans(delimiter_begin)


  if("${delimiter_begin}" MATCHES ..)
    string(REGEX REPLACE "(.)(.)" "\\2" delimiter_end "${delimiter_begin}")
    string(REGEX REPLACE "(.)(.)" "\\1" delimiter_begin "${delimiter_begin}")
  else()
    list_pop_front(delimiters)
    ans(delimiter_end)
  endif()

  
  if("${delimiter_end}_" STREQUAL "_")
    set(delimiter_end "${delimiter_begin}")
  endif()
  #set(regex "${delimiter_begin}(([^${delimiter_end}])*)${delimiter_end}")
  set(delimiter_end "${delimiter_end}" PARENT_SCOPE)
  #set(regex "${delimiter_begin}(([^${delimiter_end}\\]|(\\[${delimiter_end}])|\\\\)*)${delimiter_end}")
  regex_escaped_string("${delimiter_begin}" "${delimiter_end}")
  ans(regex)
  return_ref(regex)
endfunction()







function(regex_escaped_string delimiter_begin delimiter_end)

  set(regex "${delimiter_begin}(([^${delimiter_end}\\]|([\\][${delimiter_end}])|([\\][\\])|([\\]))*)${delimiter_end}")
  return_ref(regex)
endfunction()





macro(http_regexes)
  #https://www.ietf.org/rfc/rfc2616
  set(http_version_regex "HTTP/[0-9]\\.[0-9]")
  set(http_header_regex "([a-zA-Z0-9_-]+): ([^\r]+)\r\n")
  set(http_headers_regex "(${http_header_regex})*")

  set(http_method_regex "GET|HEAD|POST|PUT|DELETE|TRACE|CONNECT")
  set(http_request_uri_regex "[^ ]+")
  set(http_request_line_regex "(${http_method_regex}) (${http_request_uri_regex}) (${http_version_regex})\r\n")
  set(http_request_header_regex "(${http_request_line_regex})(${http_headers_regex})")

  set(http_status_code "[0-9][0-9][0-9]")
  set(http_reason_phrase "[^\r]+")
  set(http_response_line_regex "(${http_version_regex}) (${http_status_code}) (${http_reason_phrase})\r\n")
  set(http_response_header_regex "(${http_response_line_regex})(${http_headers_regex})")
endmacro()




macro(regex_json)
  
  if(NOT __regex_json_defined)
    set(__regex_json_defined)
    set(regex_json_string_literal "\"([^\"\\]|([\\][\"])|([\\][\\])|([\\]))*\"")
    set(regex_json_number_literal "[0-9]+")
    set(regex_json_bool_literal "(true)|(false)")
    set(regex_json_null_literal "null")
    set(regex_json_literal "(${regex_json_string_literal})|(${regex_json_number_literal})|${regex_json_bool_literal}|(${regex_json_null_literal})")
  
    set(regex_json_string_token "\"(([\\][\\]\")|(\\\\.)|[^\"\\])*\"")

    set(regex_json_number_token "[0-9\\.eE\\+\\-]+")
    set(regex_json_bool_token "(true)|(false)")
    set(regex_json_null_token "null")
    set(regex_json_object_begin_token "{")
    set(regex_json_object_end_token "}")
    string_codes()
    set(regex_json_array_begin_token "${bracket_open_code}")
    set(regex_json_array_end_token "${bracket_close_code}")
    set(regex_json_separator_token ",")
    set(regex_json_keyvalue_token ":")
    set(regex_json_whitespace_token "[ \t\n\r]+")
    set(regex_json_token "(${regex_json_string_token})|(${regex_json_number_token})|${regex_json_bool_token}|(${regex_json_null_token})|${regex_json_object_begin_token}|${regex_json_object_end_token}|${regex_json_array_begin_token}|${regex_json_array_end_token}|${regex_json_separator_token}|${regex_json_keyvalue_token}|${regex_json_whitespace_token}")


  endif()
endmacro()





  function(regex_match regex)
    string(REGEX MATCH "${regex}" ans ${ARGN})
    return_ref(ans)
  endfunction()





  ## match replace with easier syntax 
  ## $0-$9 is replaces with the corresponding regex match group
  function(regex_match_replace match replace)
    set(CMAKE_MATCH_0)
    set(CMAKE_MATCH_1)
    set(CMAKE_MATCH_2)
    set(CMAKE_MATCH_3)
    set(CMAKE_MATCH_4)
    set(CMAKE_MATCH_5)
    set(CMAKE_MATCH_6)
    set(CMAKE_MATCH_7)
    set(CMAKE_MATCH_8)
    set(CMAKE_MATCH_9)
    if("${ARGN}" MATCHES "${match}")
      if(replace)
        set(result "${replace}")
        foreach(i RANGE 0 9)
          string(REPLACE "$${i}" "${CMAKE_MATCH_${i}}" result "${result}")
        endforeach()
        return_ref(result)
      endif()
    endif() 
    return()
  endfunction()





  function(regex_replace regex replace)
    string(REGEX REPLACE "${regex}" "${replace}" ans ${ARGN})
    return_ref(ans)
  endfunction()





# contains common regular expression 
macro(regex_uri)
  if(NOT __regex_uri_included)
    set(__regex_uri_included true)
    set(lowalpha_range "a-z")
    set(lowalpha "[${lowalpha_range}]")
    set(upalpha_range "A-Z")
    set(upalpha "[${upalpha_range}]")
    set(digit_range "0-9")
    set(digit "[${digit_range}]")
    set(alpha_range "${lowalpha_range}${upalpha_range}")
    set(alpha "[${alpha_range}]")
    set(alphanum_range "${alpha_range}${digit_range}")
    set(alphanum "[${alphanum_range}]")

    set(reserved_no_slash_range "\;\\?:@&=\\+\\$,")
    set(reserved_no_slash "[${reserved_no_slash_range}]")
    set(reserved_range "\\/${reserved_no_slash_range}")
    set(reserved "[${reserved_range}]")
    set(mark_range "\\-_\\.!~\\*'\\(\\)")
    set(mark "[${mark_range}]")
    set(unreserved_range "${alpha_range}${mark_range}")
    set(unreserved "[${unreserved_range}]")
    set(hex_range "${0-9A-Fa-f}") 
    set(hex "[${hex_range}]")
    set(escaped "%${hex}${hex}")


    #set(uric "(${reserved}|${unreserved}|${escaped})")
    set(uric "[^ ]")
    set(uric_so_slash "${unreserved}|${reserved_no_slash}|${escaped}")


    set(scheme_mark_range "\\+\\-\\.")
    set(scheme_mark "[${scheme_mark_range}]")
    set(scheme_delimiter ":")

    set(scheme_regex "${alpha}[${alphanum_range}${scheme_mark_range}]*")
    
    set(net_root_regex "//")
    set(abs_root_regex "/")

    set(abs_path "\\/${path_segments}")
    set(net_path "\\/\\/${authority}(${abs_path})?")

    set(authority_char "[^/\\?#]" )
    set(authority_regex "${authority_char}+")

    set(segment_char "[^\\?#/ ]")
    set(segment_separator_char "/")


    set(path_char_regex "[^\\?#]")
    set(query_char_regex "[^#]")
    set(query_delimiter "\\?")
    set(query_regex "${query_delimiter}${query_char_regex}*")
    set(fragment_char_regex "[^ ]")
    set(fragment_delimiter_regex "#")
    set(fragment_regex "${fragment_delimiter_regex}${fragment_char_regex}*")

  #  ";" | ":" | "&" | "=" | "+" | "$" | "," 
    set(dns_user_info_char "(${unreserved}|${escaped}|[;:&=+$,])")
    set(dns_user_info_separator "@")
    set(dns_user_info_regex "(${dns_user_info_char}+)${dns_user_info_separator}")

    set(dns_port_seperator :)
    set(dns_port_regex "[0-9]+")
    set(dns_host_regex_char "[^:]")
    set(dns_host_regex "(${dns_host_regex_char}+)${dns_port_seperator}?")
      set(dns_domain_toplabel_regex "${alpha}(${alphanum}|\\-)*")
      set(dns_domain_label_separator "[.]")
    set(dns_domain_label_regex "[^.]+")
    set(ipv4_group_regex "(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])")
    set(ipv4_regex "${ipv4_group_regex}[\\.]${ipv4_group_regex}[\\.]${ipv4_group_regex}[\\.]${ipv4_group_regex}")
  endif()
endmacro()




## sample_copy(<sample code:/[0-9][0-9]/> <?target_dir>)
##
## copies the specified sample into the specified directroy
## samples are in the <cmakepp>/samples
  function(sample_copy sample)
      set(args ${ARGN})
      list_pop_back(args)
      ans(target_dir)
      ## copy sample to test dir 
      ## and compile cmakepp to test dir
      cmakepp_config(base_dir)  
      ans(base_dir)
      
      glob("${base_dir}/samples/${sample}*")
      ans(sample_dir )
      cp_dir("${sample_dir}" "${target_dir}")
  endfunction()




## `(<f:<cnf>> <clauses:{<<index>:<literal index...>...>}> <assignments:{<<literal index>:<bool>...>} <decisions:<literal index>...>)`
## 
## propagates the unit clauses in the cnf consisting of clauses
## 
## propagates assignment values for the specified `<decisions>`
## sets literal assignments in <assignments>
## returns the indices of the deduced literals
## returns "conflict" if an assignment conflicts with an existing one in <assignments>
## returns "unsatisfied" if cnf is unsatisfiable 
## 
function(bcp f clauses assignments)
  #map_import_properties(${f} literal_inverse_map) ## simplification inverse = i+-1

  # bcp_deduce_assignments("${f}" "${clauses}" "${assignments}")
  # ans(deduced_assignments)

  # if("${deduced_assignments}" MATCHES "(conflict)|(unsatisfied)")
  #   return_ref(deduced_assignments)
  # endif()
  
  # set(all_deductions ${deduced_assignments})
 #set(propagation_queue ${deduced_assignments} ${ARGN})
 set(propagation_queue ${ARGN})
  while(true)
    ## dedpuce assignments
    bcp_deduce_assignments("${f}" "${clauses}" "${assignments}")
    ans(deduced_assignments)

    if("${deduced_assignments}" MATCHES "(conflict)|(unsatisfied)")
      return_ref(deduced_assignments)
    endif()

    list(APPEND propagation_queue ${deduced_assignments})
    list(APPEND all_deductions ${deduced_assignments})
    list_remove_duplicates(propagation_queue)

    list(LENGTH propagation_queue continue)
    if(NOT continue)
      break()
    endif()


    
    list_pop_front(propagation_queue)
    ans(li)

    map_tryget(${assignments} ${li})
    ans(vi)

    bcp_simplify_clauses("${f}" "${clauses}" "${li}" "${vi}")
  endwhile()
  return_ref(all_deductions)
endfunction()





## `()->`
##
## tries to add a assignment for literal li
## if the assignment does not exist it is set and true is returned
## if an assignment exists and it conflicts with the new assignemnt return false
## if the assignment exists and is equal to the new assignment nochange is returned
## if(result) => ok
## if(NOT result) => conflict
function(bcp_assignment_add f assignments li value)
#  print_vars(assignments li value)
  map_tryget("${assignments}" ${li})
  ans(existing_value)
  if("${existing_value}_" STREQUAL "_")
    map_set(${assignments} ${li} ${value})
    return(true)
  elseif(NOT "${existing_value}" STREQUAL "${value}")
    return(false)
  endif()
  return(nochange)
endfunction()




## `()->`
##
## takes a list of clauses and deduces all assignments from unit clauses
## storing them in assignments and returning their literal indices
## returns conflict if a deduced assignment conflicts with an existing assignment
## return unsatisfied if clauses contains at least one unsatisfiable clause
function(bcp_deduce_assignments f clauses assignments)
    map_import_properties(${f} literal_inverse_map)
    bcp_extract_unit_clauses("${f}" "${clauses}")
    ans(unit_clauses)


    if("${unit_clauses}" MATCHES "unsatisfied")
      return(unsatisfied)
    endif()

    set(deduced_assignments)
    foreach(unit_clause ${unit_clauses})
      bcp_assignment_add("${f}" "${assignments}" "${unit_clause}" true)
      ans(ok)
      if(NOT ok)
        return(conflict)
      endif()

      map_tryget(${literal_inverse_map} ${unit_clause})
      ans(unit_clause_inverse)

     # print_vars(unit_clause unit_clause_inverse)

      bcp_assignment_add("${f}" "${assignments}" "${unit_clause_inverse}" false)
      ans(ok)
    #  print_vars(ok)
      if(NOT ok)
        return(conflict)
      endif()
      #  messaGE(FORMAT "  deduced {f.literal_map.${unit_clause}} to be true ")
      #  messaGE(FORMAT "  deduced {f.literal_map.${unit_clause_inverse}} to be false ")

      list(APPEND deduced_assignments ${unit_clause}  ${unit_clause_inverse} )
    endforeach()
    list_remove_duplicates(deduced_assignments)
    return_ref(deduced_assignments)
endfunction()




## `()->`
##
## returns unsatisfied if a clause is unsatisfieable
## returns indices of unit_clauses' literal
## else returns nothing 
## sideffect updates clauses map removes unit clauses
function(bcp_extract_unit_clauses f clauses)
 # map_import_properties(${f})
  map_keys(${clauses})
  ans(clause_indices)



  set(unit_literals)


  foreach(ci   ${clause_indices}  )
    # ## get clause's literal indices
    map_tryget(${clauses} ${ci})
    ans(clause)

    if("${clause}_" STREQUAL "_")
      return(unsatisfied)
    endif()

    ## check if clause has become unit
    list(LENGTH clause literal_count)
    if("${literal_count}" EQUAL 1)
      ## if so remove it and collect the unit literal
      map_remove(${clauses} ${ci})
      list(APPEND unit_literals ${clause})
    else()
      ## update clause 
      map_set(${clauses} ${ci} ${clause})
    endif()

  endforeach()
  return_ref(unit_literals)
endfunction()





## `(...)->...` 
##
## 
## assigns all pure literals (and there inverse) 
## removes all clauses an containing one from clauses
## returns all indices of pure literals
## returns conflict if a pure literal assignment conflicts with an existing one
function(bcp_pure_literals_assign f clauses assignments)
  bcp_pure_literals_find(${f} ${clauses})
  ans(pure_literals)

  if("${pure_literals}_" STREQUAL "_")
    return()
  endif()

  map_import_properties(${f} literal_inverse_map)

 # print_vars(assignments pure_literals)

  ## set assignments
  foreach(pure_literal ${pure_literals})
    bcp_assignment_add(${f} ${assignments} ${pure_literal} true)
    ans(ok)
    if(NOT ok)
      return(conflict)
    endif()

    map_tryget(${literal_inverse_map} ${pure_literal})
    ans(inverse)

    bcp_assignment_add(${f} ${assignments} ${inverse} false)
    ans(ok)
    if(NOT ok)
      return(conflict)
    endif()
  endforeach()

  ## remove clauses containing pure literal
  map_keys(${clauses})
  ans(clause_indices)

  foreach(ci ${clause_indices})
    map_tryget(${clauses} ${ci})
    ans(clause)

    list_contains_any(clause ${pure_literals})
    ans(contains_any)
  
    if(contains_any)
      map_remove(${clauses} ${ci})
    endif()      
  endforeach()
  return_ref(pure_literals)
endfunction()




## `(<f:<cnf>> <clauses:{<<clause index>:<literal index...>...>}>)-><literal index...>`
##
## returns a list of literal indices of pure literals in clauses
function(bcp_pure_literals_find f clauses)
  map_import_properties(${f} literal_inverse_map)
  map_values(${clauses})
  ans(clause_literals)

  ## if all clauses are empty return nothing
  if("${clause_literals}_" STREQUAL "_")
    return()
  endif()

  ## loop through all literals of all clauses and check if its inverse was 
  ## not found append it to pure_literals (which are returned)
  list(REMOVE_DUPLICATES clause_literals)
  set(pure_literals)
  while(NOT "${clause_literals}_" STREQUAL "_")
    list_pop_front(clause_literals)
    ans(current_literal)

    map_tryget(${literal_inverse_map} ${current_literal})
    ans(inverse_literal)

    list(FIND clause_literals ${inverse_literal} inverse_found)

    if(${inverse_found} LESS 0)
      ## current literal is pure
      list(APPEND pure_literals ${current_literal})
    else()
      list(REMOVE_AT clause_literals ${inverse_found})
    endif()
  endwhile()

  return_ref(pure_literals)
endfunction()





## `(<f:<cnf>> <clause:<literal index...>> <li:literal index> <value:<bool>>)-><literal index..>|"satisfied"`
##
## returns `"satisfied"` if clause is satisfied by literal assignment
## returns `<null>` if clause is unsatisfiable
## returns clause with `<li>` removed if `<value>` is false
function(bcp_simplify_clause f clause li value)
  list(FIND clause ${li} found)

  if("${found}" LESS 0)
    ## literal not found in clause -> no change 
    ## if clause was unsatisfied it stays unsatisfied
    return_ref(clause)
  endif()

  if(value)
    ## literal is in clause and is true => clause is satisfied
    return(satisfied)
  endif()

  ## if clause is not unsatisfied
  ## remove false value from clause as it does not change the result of clause
  if(clause)
    list(REMOVE_ITEM clause ${li})
  endif()

  ## return rest of clause
  ## if clause was unsatisfied it stays unsatisfied
  return_ref(clause)
endfunction()




## `()->`
##
## takes a set of clauses and simplifies them by 
## setting li to value
## removes all li that are false from clauses
## removes clauses which are satisfied
function(bcp_simplify_clauses f clauses li value)
 # map_import_properties(${f})

  map_keys(${clauses})
  ans(clause_indices)

  set(unit_literals)

  foreach(ci ${clause_indices})
    ## get clause's literal indices
    map_tryget(${clauses} ${ci})
    ans(clause)

    ## propagate new literal value to clause
    bcp_simplify_clause("${f}" "${clause}" "${li}" "${value}")
    ans(clause)

    if("${clause}_" STREQUAL "satisfied_")
      ## remove clause because it is always true
      map_remove("${clauses}" "${ci}")
    else()
      map_set(${clauses} ${ci} ${clause})
    endif()
  endforeach()
endfunction()




## `(<clause map: <sequence>>)-> <cnf>`
##
##  
## 
## creates a conjunctive normal form from the specified input
## ```
## <cnf> ::= {
##   c_n : <uint>  # the number of clauses
##   c_last : <int>  # c_n - 1
##   clause_map : { <<clause index>:<clause>>... }
##   clause_atom_map : { <<clause index> : <atom index>... >...}
##   clause_literal_map : { <<clause index> : <literal index>...>...}
##   
##   a_n : <uint> # the number of atoms
##   a_last : <int>  # a_n - 1 
##   atom_map : { <<atom index>:<atom>>... }
##   atom_clause_map  : { <<atom index>:<clause index>...>...}
##   atom_literal_map :  {}
##   atom_literal_negated_map : {}
##   atom_literal_identity_map : {}
##   atom_index_map : {}
##   
##   l_n : <uint>
##   l_last : <int>
##   literal_map : {}
##   literal_atom_map : {}
##   literal_inverse_map : {}
##   literal_negated_map : {}
##   literal_index_map : {}
##   literal_clause_map : {}
## }
## ```
function(cnf clause_map)

  map_keys("${clause_map}")
  ans(clause_indices)

  sequence_new()
  ans(literal_map)
  sequence_new()
  ans(atom_map)
  sequence_new()
  ans(atom_literal_map)
  sequence_new()
  ans(literal_atom_map)
  map_new()
  ans(literal_index_map)
  map_new()
  ans(atom_index_map)
  sequence_new()
  ans(literal_negated_map)
  sequence_new()
  ans(literal_inverse_map)
  sequence_new()
  ans(atom_literal_negated_map)
  sequence_new()
  ans(atom_literal_identity_map)

  map_values(${clause_map})
  ans(tmp)
  set(literals)
  foreach(literal ${tmp})
    if("${literal}" MATCHES "^!?(.+)")
      list(APPEND literals ${CMAKE_MATCH_1})
    endif()
  endforeach()
  list_remove_duplicates(literals)

  foreach(literal ${literals})
      sequence_add(${atom_map} "${literal}")
      ans(ai)
      sequence_add(${literal_map} "${literal}")
      ans(li)
      sequence_add(${literal_map} "!${literal}")
      ans(li_neg)

      sequence_add(${literal_negated_map} false)
      sequence_add(${literal_negated_map} true)
      sequence_add(${atom_literal_map} ${li} ${li_neg})

      sequence_add(${literal_atom_map} ${ai})
      sequence_add(${literal_atom_map} ${ai})
      
      sequence_add(${atom_literal_negated_map} ${li_neg})
      sequence_add(${atom_literal_identity_map} ${li})

      sequence_add(${literal_inverse_map} ${li_neg})
      sequence_add(${literal_inverse_map} ${li})

      map_set(${literal_index_map} "${literal}" ${li})
      map_set(${literal_index_map} "!${literal}" ${li_neg})
      map_set(${atom_index_map} "${literal}" "${ai}")

  endforeach()

  map_new()
  ans(clause_atom_map)

  map_new()
  ans(clause_literal_map)

  map_new()
  ans(literal_clause_map)

  map_new()
  ans(atom_clause_map)

  foreach(ci ${clause_indices})
    map_tryget("${clause_map}" ${ci})
    ans(clause)
    map_set(${clause_atom_map} ${ci})
    map_set(${clause_literal_map} ${ci})
    foreach(literal ${clause})
      
      map_tryget(${literal_index_map} "${literal}")
      ans(li)

      map_tryget(${literal_atom_map} ${li})
      ans(ai)

      map_append_unique(${clause_atom_map} ${ci} ${ai})
      map_append_unique(${clause_literal_map} ${ci} ${li})
      map_append_unique(${literal_clause_map} ${li} ${ci})
      map_append_unique(${atom_clause_map} ${ai} ${ci})
    endforeach()
  endforeach()

  sequence_count(${clause_map})
  ans(c_n)
  math(EXPR c_last "${c_n} - 1")

  sequence_count(${literal_map})
  ans(l_n)
  math(EXPR l_last "${l_n} - 1")

  sequence_count(${atom_map})
  ans(a_n)
  math(EXPR a_last "${a_n} - 1")
  #json_print(${clause_map})

  map_capture_new(
    c_n
    c_last
    clause_map
    clause_atom_map
    clause_literal_map

    a_n
    a_last
    atom_map
    atom_clause_map
    atom_literal_map
    atom_literal_negated_map
    atom_literal_identity_map
    atom_index_map

    l_n 
    l_last
    literal_map
    literal_atom_map
    literal_inverse_map
    literal_negated_map
    literal_index_map
    literal_clause_map
  )
  ans(cnf)

  return_ref(cnf)

endfunction()





  function(cnf_from_encoded_list)
    arguments_sequence(0 ${ARGC})
    ans(clauses)
    cnf("${clauses}")
    return_ans()
  endfunction()




##
##
##
function(create_watch_list f assignments)   
  map_new()
  ans(watch_list)
  
  map_tryget(${f} c_last)
  ans(c_last)
    
  foreach(ci RANGE 0 ${c_last})
    update_watch_list_clause("${f}" "${watch_list}" "${assignments}" "${ci}")
  endforeach()

  return_ref(watch_list)
endfunction()





##
##
## naive implementation of Basic Davis-Putnam Backtrack Search
## http://www.princeton.edu/~chaff/publication/DAC2001v56.pdf
##
function(dp_naive f)
  dp_naive_init(${f})
  ans(context)
  set(initial_context ${context})
  while(true)
    ## decide which literal to try next to satisfy clauses
    ## returns true if decision was possible
    ## if no decision is made all clauses are satisfied
    ## and the algorithm terminates with success
    dp_naive_decide()
    ans(decision)
    if(NOT decision)
      dp_naive_finish(satsifiable)
      return_ans()
    endif()

    ## propagate decision 
    ## if a conflict occurs backtrack 
    ## when backtracking is impossible the algorithm terminates with failure
    while(true)

      dp_naive_bcp()
      ans(bcp)
      if(bcp)
        break()
      endif()

      ## backtrack 
      dp_naive_resolve_conflict()
      ans(resolved)

      if(NOT resolved)
        dp_naive_finish(not_satisfiable)
        return_ans()
      endif()
    endwhile()
  endwhile()

  message(FATAL_ERROR "unreachable code")
endfunction()


function(dp_naive_finish outcome)
  
  if("${outcome}" STREQUAL "satsifiable")
    map_peek_back(${context} decision_stack)
    ans(dl)
    map_tryget(${dl} assignments)
    ans(assignments)

    map_new()
    ans(result)
    map_set(${result} success true)
    map_set(${result} outcome ${outcome})
    map_set(${result} context ${context})
    map_set(${result} initial_context ${initial_context})
    map_set(${result} assignments ${assignments})
    return(${result})
  else()

    map_new()
    ans(result)
    map_set(${result} success false)
    map_set(${result} outcome ${outcome})
    map_set(${result} context ${context})
    map_set(${result} initial_context ${initial_context})
    #map_set(${result} assignments)
    return(${result})
  endif()
  return()
endfunction()


function(dp_naive_init f)
  map_import_properties(${f} clause_literal_map)
  ## add decision layer NULL to decision stack
  
  map_new()
  ans(assignments)
  map_duplicate(${clause_literal_map})
  ans(clauses)

  map_new()
  ans(decision_layer)
  map_set(${decision_layer} depth 0)
  map_set(${decision_layer} decision ${decision})
  map_set(${decision_layer} value false)
  map_set(${decision_layer} tried_both_ways false)
  map_set(${decision_layer} clauses ${clauses})
  map_set(${decision_layer} assignments "${assignments}")
  map_set(${decision_layer} parent)


  map_new()
  ans(context)

  map_set(${context} f ${f})
  map_set(${context} decision_stack ${decision_layer})

  return(${context})
endfunction()

function(dp_naive_push_decision parent decision value tried_both_ways)

  map_import_properties(${parent} clauses assignments)

  map_tryget(${context} decision_stack)
  ans(decision_stack)
  list(LENGTH decision_stack decision_depth)

  map_duplicate(${clauses})
  ans(clauses)

  map_duplicate(${assignments})
  ans(assignments)

  map_new()
  ans(dl)

  map_set(${dl} depth ${decision_depth})
  map_set(${dl} decision ${decision})
  map_set(${dl} value ${value})
  map_set(${dl} tried_both_ways ${tried_both_ways})
  map_set(${dl} clauses ${clauses})
  map_set(${dl} assignments ${assignments})
  map_set(${dl} parent ${parent})
  #message(PUSH FORMAT "decided {decision} (DL{dl.depth} {context.f.literal_map.${decision}}={value})")

  map_push_back(${context} decision_stack ${dl})
endfunction()

## return false if no unassigned variables remain
## true otherwise
## adds new decision layer to decision stack
function(dp_naive_decide)
  map_peek_back(${context} decision_stack)
  ans(dl)

  map_import_properties(${dl} clauses)
  map_values(${clauses})
  ans(unassigned_literals)


  list(LENGTH unassigned_literals unassigned_literals_count)
  if(NOT unassigned_literals_count)
    return(false)
  endif()

  list(GET unassigned_literals 0 decision)

  dp_naive_push_decision(${dl} ${decision} true false)
  return(true)
endfunction()

function(dp_naive_bcp)
  map_import_properties(${context} f)

  map_peek_back(${context} decision_stack)
  ans(dl)

  map_import_properties(${dl} decision value clauses assignments)
  map_set(${assignments} ${decision} ${value})
  
  #print_vars(clauses assignments)
  bcp("${f}" "${clauses}" "${assignments}" ${decision})
  ans(result)
  #print_vars(clauses assignments)

  #message(FORMAT "propagating {context.f.literal_map.${decision}} = ${value} => deduced: ${result}")
  #foreach(li ${result})
   # message(FORMAT "  {context.f.literal_map.${li}}=>{assignments.${li}}")
 # endforeach()
  if("${result}" MATCHES "(conflict)|(unsatisfied)")
    return(false)
  endif()

  return(true)
endfunction()



function(dp_naive_resolve_conflict)
  map_import_properties(${context} f)

  ## undo decisions until a decision is found which was not 
  ## tried the `other way` ie inversing the literals value
  set(conflicting_decision)
  while(true)
    map_pop_back(${context} decision_stack)
    ans(dl)
    ## store conflicting_decision
    map_set(${dl} conflicting_decision ${conflicting_decision})
    set(conflicting_decision ${dl})
    map_tryget(${dl} tried_both_ways)
    ans(tried_both_ways)
    if(NOT tried_both_ways)
      break()
    endif()
  endwhile()


  # d = most recent decision not tried `both ways`
  map_tryget(${dl} decision)
  ans(d)
  if("${d}_" STREQUAL "_")
    ## decision layer 0 reached -> cannot resolve
    return(false)
  endif()


  ## flip value
  map_tryget(${dl} value)
  ans(value)
  eval_truth(NOT value)
  ans(value)

  map_tryget(${dl} parent)
  ans(parent)

  ## pushback decision layer with value inverted
  dp_naive_push_decision(${parent} ${d} ${value} true)

  return(true)
endfunction()




##
##
## updates the watch list 
## removes newly assigned literal
## add watches to next unassigned literal 
function(update_watch_list f watch_list assignments new_assignment)

  map_tryget("${watch_list}" ${new_assignment})
  ans(watched_clauses)

  map_remove("${watchlist}" ${new_assignment})

  map_tryget(${f} clause_literals)
  ans(clause_literals)

  foreach(watched_clause ${watched_clauses})
    update_watch_list_clause("${f}" "${watch_list}" "${assignments}" "${watched_clause}")
  endforeach()

endfunction()




##
##
## updates a single clause int the watch list
function(update_watch_list_clause f watch_list assignments watched_clause)
  map_tryget("${f}" clause_literals)
  ans(clause_literals)

  map_tryget(${clause_literals} ${watched_clause})
  ans(watched_clause_literals)
  
  ## loop through all literals for watched clause
  ## get the currently watched literals from watch clause
  set(current_watch_count 0)

  while(${current_watch_count} LESS 2 AND NOT "${watched_clause_literals}_" STREQUAL "_" )
    list_pop_front(watched_clause_literals)
    ans(current_literal)
    if(NOT "${current_literal}" EQUAL "${new_assignment}")
      map_tryget("${assignments}" "${new_assignment}")
      ans(is_assigned)
      if(NOT is_assigned)
        map_append_unique("${watch_list}" "${current_literal}" "${watched_clause}")
        math(EXPR current_watch_count "${current_watch_count} + 1")
      endif()
    endif()
  endwhile()
endfunction()





##
##
function(atom_to_literal_assignments f atom_assignments)
  map_import_properties(${f} atom_index_map atom_literal_identity_map atom_literal_negated_map)

  map_keys(${atom_assignments})
  ans(atoms)
  map_new()
  ans(result)
  foreach(atom ${atoms})
    map_tryget(${atom_index_map} ${atom})
    ans(ai)
    map_tryget(${atom_literal_identity_map} ${ai})
    ans(li)
    map_tryget(${atom_literal_negated_map} ${ai})
    ans(li_negated)
    map_tryget(${atom_assignments} ${atom})
    ans(value)
    eval_truth(NOT value)
    ans(value_negated)
    map_set(${result} ${li} ${value})
    map_set(${result} ${li_negated} ${value_negated})
  endforeach()
  return_ref(result)
endfunction()







## takes a literal assignment model 
## returns the atom assignments
function(literal_to_atom_assignments f literal_assignments)
  map_tryget(${f} l_last)
  ans(l_last)
  map_tryget(${f} literal_negated_map)
  ans(literal_negated_map)
  map_tryget(${f} literal_atom_map)
  ans(literal_atom_map)
  map_tryget(${f} atom_map)
  ans(atom_map)
  map_new()
  ans(atom_assignments)
  foreach(i RANGE 0 ${l_last})
    map_tryget(${literal_assignments} ${i})
    ans(value)
  #  print_vars(i value)
    if(NOT "${value}_" STREQUAL "_")
      map_tryget(${literal_atom_map} ${i})
      ans(ai)

      map_tryget(${atom_map} ${ai})
      ans(atom_name)

      #print_vars(atom_map atom_name ai)

      map_tryget(${literal_negated_map} ${i})
      ans(negated)
      #message("value ${atom_name} ${i} ${value}")
      if(negated)
        eval_truth(NOT value)
        ans(value)
      endif()

      map_set(${atom_assignments} ${atom_name} ${value})
    endif()
  endforeach()  
  return_ref(atom_assignments)
endfunction()







  function(print_cnf f)
    scope_import_map(${f})
    print_multi(${c_last} clauses clause_literals clause_atoms)
    print_multi(${a_last} atoms atom_literals atom_clauses)
    print_multi(${l_last} literals literal_inverse literal_negated literal_clauses literal_atom)

  endfunction()

  ## new
  function(cnf_print f)
    scope_import_map(${f})
    print_multi(${c_last} clause_map clause_literal_map clause_atom_map)
    print_multi(${a_last} atom_map atom_literal_map atom_clause_map)
    print_multi(${l_last} literal_map literal_inverse_map literal_negated_map literal_clause_map literal_atom_map)

  endfunction()






function(create_watch_list f assignments)   
  map_new()
  ans(watch_list)
  
  map_tryget(${f} c_last)
  ans(c_last)
    
  foreach(ci RANGE 0 ${c_last})
    update_watch_list_clause("${f}" "${watch_list}" "${assignments}" "${ci}")
  endforeach()

  return_ref(watch_list)
endfunction()






  ## updates the watch list 
  ## removes newly assigned literal
  ## add watches to next unassigned literal 
  function(update_watch_list f watch_list assignments new_assignment)

    map_tryget("${watch_list}" ${new_assignment})
    ans(watched_clauses)

    map_remove("${watchlist}" ${new_assignment})

    map_tryget(${f} clause_literals)
    ans(clause_literals)

    foreach(watched_clause ${watched_clauses})
      update_watch_list_clause("${f}" "${watch_list}" "${assignments}" "${watched_clause}")
    endforeach()

  endfunction()






## updates a single clause int the watch list
function(update_watch_list_clause f watch_list assignments watched_clause)
  map_tryget("${f}" clause_literals)
  ans(clause_literals)

  map_tryget(${clause_literals} ${watched_clause})
  ans(watched_clause_literals)
  
  ## loop through all literals for watched clause
  ## get the currently watched literals from watch clause
  set(current_watch_count 0)

  while(${current_watch_count} LESS 2 AND NOT "${watched_clause_literals}_" STREQUAL "_" )
    list_pop_front(watched_clause_literals)
    ans(current_literal)
    if(NOT "${current_literal}" EQUAL "${new_assignment}")
      map_tryget("${assignments}" "${new_assignment}")
      ans(is_assigned)
      if(NOT is_assigned)
        map_append_unique("${watch_list}" "${current_literal}" "${watched_clause}")
        math(EXPR current_watch_count "${current_watch_count} + 1")
      endif()
    endif()
  endwhile()
endfunction()





# clears the current local scope of any variables
function(scope_clear)
  scope_keys()
  ans(vars)
  foreach (var ${vars})
    set(${var} PARENT_SCOPE)
  endforeach()
endfunction()




# Exports the curretn scope of local variables into a map
function(scope_export_map)
  get_cmake_property(_variableNames VARIABLES)
  map_new()
  ans(_exportmapname)
  foreach (_variableName ${_variableNames})
    map_set("${_exportmapname}" "${_variableName}" "${${_variableName}}")
  endforeach()
  return_ref(_exportmapname)
endfunction()




# creates a local variable for every key value pair in map
# if the optional prefix is given this will be prepended to the variable name
function(scope_import_map map)
	set(prefix ${ARGN})

	map_keys(${map})
	ans(keys)

	foreach(key ${keys})
		map_tryget(${map}  ${key})
		ans(value)
		set("${prefix}${key}" ${value} PARENT_SCOPE)
	endforeach()
endfunction()






# returns all currently defined variables of the local scope
function(scope_keys)
  get_cmake_property(_variableNames VARIABLES)
  return_ref(_variableNames)
endfunction()




# print the local scope as json
function(scope_print)
  scope_export_map()
  ans(scope)
  json_print(${scope})
  return()
endfunction()




function(semver string_or_version)
  if(NOT string_or_version)
    return()
  endif()
  is_map(${string_or_version} )
  ans(ismap)
  if(ismap)
    return(${string_or_version})
  endif()
  semver_parse_lazy(${string_or_version})
  ans(version)
  return(${version})
endfunction()




# compares the semver on the left and right
# returns -1 if left is more up to date
# returns 1 if right is more up to date
# returns 0 if they are the same
function(semver_compare  left right)
 semver_parse(${left} )
 ans(left)
 semver_parse(${right})
 ans(right)


  scope_import_map(${left} left_)
  scope_import_map(${right} right_)

 semver_component_compare( ${left_major} ${right_major})
 ans(cmp)
 if(NOT ${cmp} STREQUAL 0)
  return(${cmp})
endif()
 semver_component_compare( ${left_minor} ${right_minor})
 ans(cmp)
 if(NOT ${cmp} STREQUAL 0)
  return(${cmp})
endif()
 
 semver_component_compare( ${left_patch} ${right_patch})
 ans(cmp)
 if(NOT ${cmp} STREQUAL 0)
  return(${cmp})
endif()


 if(right_prerelease AND NOT left_prerelease)
  return(-1)
 endif()

 if(left_prerelease AND NOT right_prerelease)
  return(1)
 endif()
 # iterate through all identifiers of prerelease
 while(true)
    list_pop_front(left_tags)
    ans(left_current)

    list_pop_front(right_tags)
    ans(right_current)

    # check for larger set
    if(right_current AND NOT left_current)
      return(1)
    elseif(left_current AND NOT right_current)
      return(-1)
    elseif(NOT left_current AND NOT right_current)
      # equal
      return(0)
    endif()

      # compare component
   semver_component_compare( ${left_current} ${right_current})
ans(cmp)

   #   message("asd '${left_current}'  '${right_current}' -> ${cmp}")
   if(NOT ${cmp} STREQUAL 0)
    return(${cmp})
   endif()



    
 endwhile()
 
 return(0)

endfunction()





 function(semver_component_compare left right)
 # message("comapring '${left}' to '${right}'")
    string_isempty( "${left}")
    ans(left_empty)
    string_isempty( "${right}")
    ans(right_empty)

    # filled has precedence before nonempty
    if(left_empty AND right_empty)
      return(0)
    elseif(left_empty AND NOT right_empty)
      return(1)
    elseif(right_empty AND NOT left_empty)
      return(-1)
    endif() 


    string_isnumeric( "${left}")
    ans(left_numeric)
    string_isnumeric( "${right}")
    ans(right_numeric)

    # if numeric has precedence before alphanumeric
    if(right_numeric AND NOT left_numeric)
      return(-1)
    elseif(left_numeric AND NOT right_numeric)
      return(1)
    endif()


   
    if(left_numeric AND right_numeric)
      if(${left} LESS ${right})
        return(1)
      elseif(${left} GREATER ${right})
        return(-1)
      endif()
      return(0)
    endif()

    if("${left}" STRLESS "${right}")
      return(1)
    elseif("${left}" STRGREATER "${right}")
      return(-1)
    endif()

    return(0)
 endfunction()






function(semver_constraint constraint_ish)
  map_get_special(${constraint_ish} "semver_constraint")
  ans(is_semver_constraint)
  if(is_semver_constraint)
    return_ref(constraint_ish)
  endif()

  is_map(${constraint_ish})
  ans(ismap)
  if(ismap)
    return()
  endif()

  # return cached value if it exists
 # cache_return_hit("${constraint_ish}")

  # compute and cache value
  semver_constraint_compile("${constraint_ish}")
  ans(constraint)
  # cache_update("${constraint_ish}" "${constraint}" const)

  return_ref(constraint)

endfunction()




function(semver_constraint_compile constraint)
  set(ops "\\(\\)\\|,!=~><")
    
  if("${constraint}" STREQUAL "*")
    set(constraint ">=0.0.0")
  endif()
  string(REGEX REPLACE ">=([^${ops}]+)" "(>\\1|=\\1)" constraint "${constraint}")
  string(REGEX REPLACE "<=([^${ops}]+)" "(<\\1|=\\1)" constraint "${constraint}")


  string(REPLACE "!" ";NOT;" constraint "${constraint}")
  string(REPLACE "," ";AND;" constraint "${constraint}")
  string(REPLACE "|" ";OR;" constraint "${constraint}")
  string(REPLACE ")" ";);" constraint "${constraint}")
  string(REPLACE "(" ";(;" constraint "${constraint}")
  set(elements ${constraint})
  if(elements)
    list(REMOVE_DUPLICATES elements)
    list(REMOVE_ITEM elements "AND" "OR" "NOT" "(" ")" )
  endif()
  foreach(element ${elements})
    semver_constraint_element_isvalid(${element})
    ans(isvalid)
    if(NOT isvalid)
      return()
    endif()
  endforeach()
 # message("constraint ${constraint}")
 # message("elements ${elements}")
  nav(compiled_constraint.template "${constraint}")
  nav(compiled_constraint.elements "${elements}")
  map_set_special(${compiled_constraint} "semver_constraint" true)
  return(${compiled_constraint})

endfunction()






function(semver_constraint_compiled_evaluate compiled_constraint version )
  map_import_properties(${compiled_constraint} elements template)

  foreach(element ${elements})
    semver_constraint_evaluate_element("${element}" "${version}")
    ans(res)
    string(REPLACE "${element}" "${res}" template "${template}")
  endforeach()

  if(${template})
    return(true)
  endif()
  return(false)
endfunction()





  function(semver_constraint_element_isvalid element)
    string(REGEX MATCH "^[~\\>\\<=!]?([0-9]+)(\\.[0-9]+)?(\\.[0-9]+)?(-[a-zA-Z0-9\\.-]*)?(\\+[a-zA-Z0-9\\.-]*)?$" match "${element}")
    if(match)
      return(true)
    else()
      return(false)
    endif()
  endfunction()




# checks if the constraint holds for the specified version
function(semver_constraint_evaluate  constraint version)
  semver_constraint_compile("${constraint}")
  ans(compiled_constraint)
  #message("cc ${compiled_constraint}")
  if(NOT compiled_constraint)
    return(false)
  endif()
  semver_constraint_compiled_evaluate("${compiled_constraint}" "${version}")
  ans(res)
  #message("eval ${res}")
  return(${res})
endfunction()





function(semver_constraint_evaluate_element constraint version)
  string(STRIP "${constraint}" constraint)
  set(constraint_operator_regexp "^(\\<|\\>|\\~|=|!)")
  set(constraint_regexp "${constraint_operator_regexp}?(.+)$")
  string(REGEX MATCH "${constraint_regexp}" match "${constraint}")
  if(NOT match )
    return_value(false)
  endif()
  set(operator)
  set(argument)

  string(REGEX MATCH "${constraint_operator_regexp}" has_operator "${constraint}")
  if(has_operator)
    string(REGEX REPLACE "${constraint_regexp}" "\\1" operator "${constraint}")
    string(REGEX REPLACE "${constraint_regexp}" "\\2" argument "${constraint}")      
  else()
    set(operator "=")
    set(argument "${constraint}")
  endif()

  # check for equality
  if(${operator} STREQUAL "=")
    semver_normalize("${argument}")    
    semver_format("${argument}")
    ans(argument)
    semver_compare( "${version}" "${argument}")
    ans(cmp)
    if("${cmp}" EQUAL "0")
      return(true)
    endif()
    return(false)
  endif()

  # check if version is greater than constraint
  if(${operator} STREQUAL ">")
    semver_normalize("${argument}")    
    semver_format("${argument}")
    ans(argument)
    semver_compare( "${version}" "${argument}")
    ans(cmp)
    if("${cmp}" LESS 0)
      return(true)
    endif()
    return(false)
  endif()

  # cheick  if version is less than constraint
  if(${operator} STREQUAL "<")
    semver_normalize("${argument}")    
    semver_format("${argument}")
    ans(argument)
    semver_compare( "${version}" "${argument}")
    ans(cmp)
    if("${cmp}" GREATER 0)
      return(true)
    endif()
    return(false)
  endif()

  if(${operator} STREQUAL "!")
    semver_normalize("${argument}")    
    semver_format("${argument}")
    ans(argument)
    semver_compare( "${version}" "${argument}")
    ans(cmp)
    if("${cmp}" EQUAL "0")
      return(false)
    endif()
    return(true)

  endif()

  #check if version about equal to constraint
  if(${operator} STREQUAL "~")
    string(REGEX REPLACE "(.*)([0-9]+)" "\\2" upper "${argument}")
    math(EXPR upper "${upper} + 1" )
    string(REGEX REPLACE "(.*)([0-9]+)" "\\1${upper}" upper "${argument}")
    string(REGEX REPLACE "(.*)([0-9]+)" "\\1\\2" lower "${argument}")
    
    semver_constraint_evaluate_element( ">${lower}" "${version}")
    ans(lower_ok_gt)
    semver_constraint_evaluate_element( "=${lower}" "${version}")
    ans(lower_ok_eq)
    semver_constraint_evaluate_element( "<${upper}" "${version}")
    ans(upper_ok)

    if((lower_ok_gt OR lower_ok_eq) AND upper_ok)
      return(true)
    endif()
    return(false)
  endif()
  return(false)
endfunction()




 function(semver_format version)
  semver_normalize("${version}")
  ans(version)

  #map_format("{version.major}.{version.minor}.{version.patch}")
  #ans(res)
  map_tryget(${version} major)
  ans(major)
  map_tryget(${version} minor)
  ans(minor)
  map_tryget(${version} patch)
  ans(patch)
  set(res "${major}.${minor}.${patch}")

  map_tryget("${version}" prerelease)
  ans(prerelease)
  if(NOT "${prerelease}_" STREQUAL "_")
    set(res "${res}-${prerelease}")
  endif()

  map_tryget("${version}" metadata)
  ans(metadata)
  if(NOT "${metadata}_" STREQUAL "_")
    set(res "${res}+${metadata}")
  endif()

  return_ref(res)

 endfunction()




# returns true if semver a is more up to date than semver b
  function(semver_gt  a b)
    semver_compare( "${a}" "${b}") 
    ans(res)
    ans(res)
    if(${res} LESS 0)
      return(true)
    endif()
    return(false)
  endfunction()




# returns the semver which is higher of semver a  and b
   function(semver_higher a b)
    semver_gt("${a}" "${b}")
    ans(res)
    if(res)
      return(${a})
    else()
      return(${b})
    endif()
   endfunction()




#returns the version object iff the version  is valid
# else returns false
# validity:
# it has a major, minor and patch version field with valid numeric values [0-9]+
# accepts both a version string or a object
# 
function(semver_isvalid version)
  # get version object
  semver("${version}")
  ans(version)

  if(NOT version)
    return(false)
  endif()

#  nav(version.major)
  map_tryget(${version} major)
  ans(current)
  string_isnumeric( "${current}")
  ans(numeric)
  #message("curent ${current} : numeric ${numeric}")
  if(NOT numeric)
    return(false)
  endif()

  #nav(version.minor)
  map_tryget(${version} minor)
  ans(current)
  string_isnumeric("${current}")
  ans(numeric)
 # message("curent ${current} : numeric ${numeric}")
  if(NOT numeric)
    return(false)
  endif()

  #nav(version.patch)
  map_tryget(${version} patch)
  ans(current)
  string_isnumeric( "${current}")
  ans(numeric)
#  message("curent ${current} : numeric ${numeric}")
  if(NOT numeric)
    return(false)
  endif()

  return(true)
endfunction()




# returns a normalized version for a string or a object
# sets all missing version numbers to 0
# even an empty string is transformed to a version: it will be version 0.0.0 
function(semver_normalize version)
  semver("${version}")
  ans(version)

  if(NOT version)
    semver("0.0.0")
    ans(version)
  endif()

  nav(version.major)
  ans(current)
  if(NOT current)
    nav(version.major 0)
  endif() 


  nav(version.minor)
  ans(current)
  if(NOT current)
    nav(version.minor 0)
  endif() 


  nav(version.patch)
  ans(current)
  if(NOT current)
    nav(version.patch 0)
  endif() 

  return(${version})
endfunction()





function(semver_parse version_string)
  semver_parse_lazy("${version_string}")
  ans(version)
  if(NOT version)
    return()
  endif()


  semver_isvalid("${version}")
  ans(isvalid)
  if(isvalid)
    return(${version})
  endif()
  return()

  return()
  is_map("${version_string}" )
  ans(ismap)
  if(ismap)
    semver_format(version_string ${version_string})
  endif()

 set(semver_identifier_regex "[0-9A-Za-z-]+")
 set(semver_major_regex "[0-9]+")
 set(semver_minor_regex "[0-9]+")
 set(semver_patch_regex "[0-9]+")
 set(semver_identifiers_regex "${semver_identifier_regex}(\\.${semver_identifier_regex})*") 
 set(semver_prerelease_regex "${semver_identifiers_regex}")
 set(semver_metadata_regex "${semver_identifiers_regex}")
 set(semver_version_regex "(${semver_major_regex})\\.(${semver_minor_regex})\\.(${semver_patch_regex})")
 set(semver_regex "(${semver_version_regex})(-${semver_prerelease_regex})?(\\+${semver_metadata_regex})?")

  cmake_parse_arguments("" "LAZY" "MAJOR;MINOR;PATCH;VERSION;VERSION_NUMBERS;PRERELEASE;METADATA;RESULT;IS_VALID" "" ${ARGN})

  map_new()
  ans(version)

  # set result to version (this will contain partial or all of the version information)
  if(_RESULT)
    set(${_RESULT} ${version} PARENT_SCOPE)
  endif()

  string(REGEX MATCH "^${semver_regex}$" match "${version_string}")
  # check if valid
  if(NOT match)
    set(${_IS_VALID} false PARENT_SCOPE)
    return()
  endif()
  set(${_IS_VALID} true PARENT_SCOPE)

  # get version metadata and comparable part
  string_split( "${version_string}" "\\+")
  ans(parts)
  list_pop_front(parts)
  ans(version_version)

  # get version number part and prerelease part
  string_split( "${version_version}" "-")
  ans(parts)
  list_pop_front(parts)
  ans(version_prerelease)
  
  # get version numbers
  string(REGEX REPLACE "^${semver_version_regex}$" "\\1" version_major "${version_number}")
  string(REGEX REPLACE "^${semver_version_regex}$" "\\2" version_minor "${version_number}")
  string(REGEX REPLACE "^${semver_version_regex}$" "\\3" version_patch "${version_number}")

  string(REGEX REPLACE "\\." "\;" version_metadata "${version_metadata}")
  string(REGEX REPLACE "\\." "\;" version_prerelease "${version_prerelease}")

  if(_MAJOR)
    set(${_MAJOR} ${version_major} PARENT_SCOPE)
  endif()
  if(_MINOR)
    set(${_MINOR} ${version_minor} PARENT_SCOPE)
  endif()
  if(_PATCH)
    set(${_PATCH} ${version_patch} PARENT_SCOPE)
  endif()

  if(_VERSION)
    set(${_VERSION} ${version_version} PARENT_SCOPE)
  endif()

  if(_VERSION_NUMBERS)
    set(${_VERSION_NUMBERS} ${version_number} PARENT_SCOPE)
  endif()

  if(_PRERELEASE)
    set(${_PRERELEASE} ${version_prerelease} PARENT_SCOPE)
  endif()

  if(_METADATA)
    set(${_METADATA} ${version_metadata} PARENT_SCOPE)
  endif()

  if(_RESULT)
    map()
      kv(major "${version_major}")
      kv(minor "${version_minor}")
      kv(patch "${version_patch}")
      kv(prerelease "${version_prerelease}")
      kv(metadata "${version_metadata}")
    end()
    ans(_RESULT)
  endif()

endfunction()




function(semver_parse_lazy version_string)
  if(NOT version_string)
    return()
  endif()
  string_take_regex(version_string "v")


  map_new()
  ans(version)
  map_set(${version} string "${version_string}")


  set(version_number_regex "[0-9]+")
  set(identifier_regex "[0-9a-zA-Z]+")
  set(version_numbers_regex "(${version_number_regex}(\\.${version_number_regex}(\\.${version_number_regex})?)?)")

  # checks if version is of ()-()+() structure and only contains valid characters
  set(version_elements_regex "([0-9\\.]*(-[a-zA-Z0-9\\.-]*)?(\\+[a-zA-Z0-9\\.-]*)?)")
  set(valid)
  string(REGEX MATCH "^${version_elements_regex}$" valid "${version_string}")
  if(NOT valid)
    return()
  endif()
  # split into version string and prelrelease metadata
  string_split_at_first(version_numbers prerelease_and_metadata "${version_string}" "-")
  string_split_at_first(prerelease metadata "${prerelease_and_metadata}" "+")
  # parse version numbers
  if(version_numbers)
    string(REGEX MATCH "^${version_numbers_regex}$" valid "${version_numbers}")
    if(NOT valid)
      return()
    endif()
    string(REPLACE "." ";" version_numbers "${version_numbers}")
    string(REPLACE "." ";" metadatas "${metadata}")
    string(REPLACE "." ";" tags "${prerelease}")
    list_extract(version_numbers major minor patch)
    map_set(${version} numbers "${version_numbers}")
    map_set(${version} major "${major}")
    map_set(${version} minor "${minor}")
    map_set(${version} patch "${patch}")
    #nav("version.numbers" "${version_numbers}")
    #nav("version.major" "${major}")
    #nav("version.minor" "${minor}")
    #nav("version.patch" "${patch}")
  endif()

  #nav("version.prerelease" "${prerelease}")
  #nav("version.metadata" "${metadata}")
  #nav("version.metadatas" "${metadatas}")
  #nav("version.tags" "${tags}")
  map_set(${version} prerelease "${prerelease}")
  map_set(${version} metadata "${metadata}")
  map_set(${version} metadatas "${metadatas}")
  map_set(${version} tags "${tags}")

  return(${version})
endfunction()







    function(sequence_add map)
      sequence_count("${map}")
      ans(count)
      math(EXPR new_count "${count} + 1")
      map_set_special("${map}" count ${new_count})
      map_set("${map}" "${count}" ${ARGN})
      return_ref(count)
    endfunction()







    function(sequence_append map idx)
      sequence_count("${map}")
      ans(count)
      if(NOT "${idx}" LESS "${count}" OR ${idx} LESS 0)
        message(FATAL_ERROR "sequence_set: index out of range: ${idx}")
      endif()

      map_append( "${map}" "${idx}" ${ARGN} )
      
    endfunction()






    function(sequence_append_string map idx)
      sequence_count("${map}")
      ans(count)
      if(NOT "${idx}" LESS "${count}" OR ${idx} LESS 0)
        message(FATAL_ERROR "sequence_set: index out of range: ${idx}")
      endif()

      map_append_string( "${map}" "${idx}" ${ARGN} )
      
    endfunction()






    macro(sequence_count map)
      map_get_special("${map}" count)
    endmacro()







    macro(sequence_get map idx)
      map_tryget("${map}" "${idx}")
    endmacro()





    macro(sequence_index_isvalid map idx)
      map_has("${map}" "${idx}")
    endmacro()






    function(sequence_isvalid map)
      sequence_count("${map}")
      ans(is_lookup)

      if("${is_lookup}_" STREQUAL "_" )
        return(false)
      endif()
      return(true)
    endfunction()






    function(sequence_new)
      is_address("${ARGN}")
      ans(isref)
      if(NOT isref)
        map_new()
        ans(map)
      else()
        set(map ${ARGN})
      endif()

      map_set_special(${map} count 0)
      return_ref(map)
    endfunction()





    function(sequence_set map idx)
      sequence_count(${map})
      ans(count)
      sequence_isvalid("${map}" "${idx}")
      ans(isvalid)
      if(NOT isvalid)
        return(false)
      endif()
      map_set("${map}" "${idx}" ${ARGN})
      return(true)
    endfunction()




function(sequence_to_list map sublist_separator list_separator)

  map_keys(${map})
  ans(keys)
  set(result)
  set(first true)
  foreach(key ${keys})
    map_tryget(${map} "${key}")
    ans(current)
    string(REPLACE ";" "${sublist_separator}" current "${current}")
    if(first)
      set(result "${current}")
      set(first false)
    else()

      set(result "${result}${list_separator}${current}")
    endif()
  endforeach()
  return_ref(result)
endfunction()




# creates a systemwide alias callend ${name} which executes the specified command_string
#  you have to restart you shell/re-login under windows for changes to take effect 
function(alias_create name command_string)


  if(WIN32)      
    cmakepp_config(bin_dir)
    ans(bin_dir)
    set(path "${bin_dir}/${name}.bat")
    fwrite("${path}" "@echo off\r\n${command_string} %*")
    reg_append_if_not_exists(HKCU/Environment Path "${bin_dir}")
    ans(res)
    if(res)
      #message(INFO "alias ${name} was created - it will be available as soon as you restart your shell")
    else()
      #message(INFO "alias ${name} as created - it is directly available for use")
    endif()
    return(true)
  endif()


  shell_get()
  ans(shell)

  if("${shell}" STREQUAL "bash")
    path("~/.bashrc")
    ans(bc)
    fappend("${bc}" "\nalias ${name}='${command_string}'")
    #message(INFO "alias ${name} was created - it will be available as soon as you restart your shell")

  else()
    message(FATAL_ERROR "creating alias is not supported by cmakepp on your system your current shell (${shell})")
  endif()
endfunction()







function(alias_exists name)
  alias_list()
  ans(aliases)
  list_contains(aliases "${name}")
  ans(res)
  return_ref(res)
endfunction()





function(alias_list)
  message(FATAL_ERROR "not implemented")

  path("${CMAKE_CURRENT_LIST_DIR}/../bin")
  ans(path)
  


  if(WIN32)
    #file_extended_glob("${path}" "*.bat" "!cps.*" "!cutil.*")
    ans(cmds)
  set(theRegex "([^\\/])+\\.bat")
  
  list_select(cmds "[](it)regex_search({{it}} {{theRegex}})")
  ans(cmds)
  
  string(REPLACE ".bat" "" cmds "${cmds}")

  return_ref(cmds)
else()
  message(FATAL_ERROR "only implemented for windows")
endif()

endfunction()








function(alias_remove name)
  path("${CMAKE_CURRENT_LIST_DIR}/../bin")
  ans(path)
  if(WIN32)
    file(REMOVE "${path}/${name}.bat")
  else()
    message(FATAL_ERROR "only implemnted for windows")
  endif()

endfunction()









#C:\ProgramData\Oracle\Java\javapath;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Program Files (x86)\ATI Technologies\ATI.ACE\Core-Static;C:\Program Files (x86)\Windows Kits\8.1\Windows Performance Toolkit\;C:\Program Files\Microsoft SQL Server\110\Tools\Binn\;C:\Program Files (x86)\Git\cmd;C:\Program Files\Mercurial\;C:\Program Files\nodejs\;C:\Program Files (x86)\Microsoft SDKs\TypeScript\1.0\;C:\Program Files\Microsoft SQL Server\120\Tools\Binn\
#C:\ProgramData\chocolatey\bin;C:\Program Files\Mercurial;C:\Users\Tobi\AppData\Roaming\npm


# creates the bash string using the map env which contains key value pairs
function(bash_profile_compile env)
  set(res)
  map_keys(${env})
  ans(keys)
  foreach(key ${keys})
    map_tryget(${env} ${key})
    ans(val)
    set(res "${res}export ${key}=\"${val}\"\n")
  endforeach()
  return_ref(res)
endfunction()

# creates and writes the bash profile env to path (see bash_profile_compile)
function(bash_profile_write path env)
  bash_profile_compile(${env})
  ans(str)
  bash_script_create("${path}" "${str}")
  return_ans()
endfunction()

function(bash_autostart_read)
  set(session_profile_path "$ENV{HOME}/.profile")
  if(NOT EXISTS "${session_profile_path}")
    return()
  endif()
  fread("${session_profile_path}")
  ans(res)
  return_ref(res)
endfunction()

# registers
function(bash_autostart_register)
  set(session_profile_path "$ENV{HOME}/.profile")
  if(NOT EXISTS "${session_profile_path}")
    touch("${session_profile_path}")
  endif()
  fread("${session_profile_path}")
  ans(profile)

  set(profile_path "$ENV{HOME}/cmakepp.profile.sh")

  if(NOT EXISTS "${profile_path}")
    shell_script_create("${profile_path}" "")
  endif()

  if("${profile}" MATCHES "${profile_path}\n")
    return()
  endif()

  unix_path("${profile_path}")
  ans(profile_path)
  set(profile "${profile}\n${profile_path}\n")
  fwrite("${session_profile_path}" "${profile}")

  return()
endfunction()

# removes the cmake profile from $ENV{HOME}/.profile
function(bash_autostart_unregister)
  set(session_profile_path "$ENV{HOME}/.profile")
  if(NOT EXISTS "${session_profile_path}")
    return()
  endif()
  fread("${session_profile_path}")
  ans(content)
  string_regex_escape("${session_profile_path}")
  ans(escaped)
  string(REGEX REPLACE "${escaped}" "" content "${content}")
  fwrite("${session_profile_path}" "${content}")
  return()
endfunction()


# returs true if the cmakepp session profile (environment variables)are registered
function(bash_autostart_isregistered)
  set(session_profile_path "$ENV{HOME}/.profile")
  if(NOT EXISTS "${session_profile_path}")
    return(false)
  endif()
  fread("${session_profile_path}")
  ans(content)
  string_regex_escape("${session_profile_path}")
  ans(escaped)
  if("${content}" MATCHES "${escaped}")
    return(true)
  endif()
  return(false)
endfunction()





# writes the args to the console
function(echo)
  execute_process(COMMAND ${CMAKE_COMMAND} -E echo "${ARGN}")
endfunction()




# writes the args to console. does not append newline
function(echo_append)
  execute_process(COMMAND ${CMAKE_COMMAND} -E echo_append "${ARGN}")
endfunction()









# reads a line from the console.  
#  uses .bat file on windows else uses shell script file .sh
function(read_line)
  fwrite_temp("" ".txt")
  ans(value_file)

  if(WIN32)
    # thanks to Fraser999 for fixing whis to dissallow variable expansion and whitespace stripping
    # etc. See merge comments
    fwrite_temp("@echo off\nsetlocal EnableDelayedExpansion\nset val=\nset /p val=\necho !val!> \"${value_file}\"" ".bat")
    ans(shell_script)
  else()
    fwrite_temp( "#!/bin/bash\nread text\necho -n $text>${value_file}" ".sh")
    ans(shell_script)
    # make script executable
    execute_process(COMMAND "chmod" "+x" "${shell_script}")
  endif()

  # execute shell script which write the keyboard input to the ${value_file}
  execute_process(COMMAND "${shell_script}")

  # read value file
  file(READ "${value_file}" line)

  # strip trailing '\n' which might get added by the shell script. as there is no way to input \n at the end 
  # manually this does not change for any system
  if("${line}" MATCHES "(\n|\r\n)$")
    string(REGEX REPLACE "(\n|\r\n)$" "" line "${line}")
  endif()

  ## quick fix
  if("${line}" STREQUAL "ECHO is off.")
    set(line)
  endif()
  # remove temp files
  file(REMOVE "${shell_script}")
  file(REMOVE "${value_file}")
  return_ref(line)
endfunction()





# runs a shell script on the current platform
# not that
function(shell cmd)
  
  shell_get()
  ans(shell)
  if("${shell}" STREQUAL "cmd")
    fwrite_temp("@echo off\n${cmd}" ".bat")
    ans(shell_script)
  elseif("${shell}" STREQUAL "bash")
    fwrite_temp("#!/bin/bash\n${cmd}" ".sh")
    ans(shell_script)
    # make script executable
    execute_process(COMMAND "chmod" "+x" "${shell_script}")

  endif()

  # execute shell script which write the keyboard input to the ${value_file}
  set(args ${ARGN})

  list_extract_flag(args --process-handle)
  ans(return_process_handle)

  execute("${shell_script}" ${args} --process-handle)
  ans(res)

  # remove temp file
  file(REMOVE "${shell_script}")
  if(return_process_handle)
    return_ref(res)
  endif()

  map_tryget(${res} exit_code)
  ans(exit_code)

  if(NOT "_${exit_code}" STREQUAL "_0")
    return()
  endif()

  map_tryget(${res} stdout)
  ans(stdout)
  return_ref(stdout)
endfunction()






function(shell_env_append key value)
  if(WIN32)
    shell("SETX ${key} %${key}%;${value}")

  else()
    message(WARNING "shell_set_env not implemented for anything else than windows")

  endif()
endfunction()





# returns the value of the shell's environment variable ${key}
function(shell_env_get key)
  shell_get()
  ans(shell)

  if(WIN32)
    
  endif()

  if("${shell}" STREQUAL "cmd")
    #setlocal EnableDelayedExpansion\nset val=\nset /p val=\necho %val%> \"${value_file}\"
    shell_redirect("echo %${key}%")
    ans(res)
  elseif("${shell}" STREQUAL "bash")
    shell_redirect("echo $${key}")
    ans(res)
  else()
    message(FATAL_ERROR "${shell} not supported")
  endif()


    # strip trailing '\n' which might get added by the shell script. as there is no way to input \n at the end 
    # manually this does not change for any system
    if("${res}" MATCHES "(\n|\r\n)+$")
      string(REGEX REPLACE "(\n|\r\n)+$" "" res "${res}")
    endif()
    
  return_ref(res)
endfunction()






function(shell_env_prepend key value)

endfunction()






# sets a system wide environment variable 
# the variable will not be available until a new console is started
function(shell_env_set key value)
  if(WIN32)
    reg_write_value("HKCU/Environment" "${key}" "${value}")
    #message("environment variable '${key}' was written, it will be available as soon as you restart your shell")
    return()
  endif()
  

  shell_get()
  ans(shell)
    
  if("${shell}" STREQUAL "bash")
    path("~/.bashrc")
    ans(path)
    fappend("${path}" "\nexport ${key}=${value}")
    #message("environment variable '${key}' was exported in .bashrc it will be available as soon as your restart your shell")
  else()
    message(WARNING "shell_set_env not implemented")
  endif()
endfunction()







# removes a system wide environment variable
function(shell_env_unset key)
  # set to nothing
  shell_env_set("${key}" "")
  shell_get()
  ans(shell)
  if("${shell}_" STREQUAL "cmd_")
    shell("REG delete HKCU\Environment /V ${key}")
  else()
    message(WARNING "shell_env_unset not implemented for anything else than windows")
  endif()
endfunction()






# returns which shell is used (bash,cmd) returns false if shell is unknown
function(shell_get)
  if(WIN32)
    return(cmd)
  else()
    return(bash)
  endif()

endfunction()







# returns the extension for a shell script file on the current console
# e.g. on windows this returns bat on unix/bash this returns bash
# uses shell_get() to determine which shell is used
function(shell_get_script_extension)
  shell_get()
  ans(shell)
  if("${shell}" STREQUAL "cmd")
    return(bat)
  elseif("${shell}" STREQUAL "bash")
    return(sh)
  else()
    message(FATAL_ERROR "no shell could be recognized")
  endif()

endfunction()





# 
function(shell_path_add path)
  set(args ${ARGN})
  list_extract_flag(args "--prepend")
  ans(prepend)

  shell_path_get()
  ans(paths)
  path("${path}")
  ans(path)
  list_contains(paths "${path}")
  ans(res)
  if(res)
    return(false)
  endif()


  if(prepend)
    set(paths "${path};${paths}")
  else()
    set(paths "${paths};${path}")
  endif()

  shell_path_set(${paths})

  return(true)
endfunction()




function(shell_path_get)
    shell_env_get(Path)
    ans(paths)
    set(paths2)
    foreach(path ${paths})
      file(TO_CMAKE_PATH path "${path}")
      list(APPEND paths2 "${path}")
    endforeach()
    return_ans(paths2)

endfunction()







function(shell_path_remove path)
  shell_path_get()
  ans(paths)

  path("${path}")
  ans(path)

  list_contains(paths "${path}")
  ans(res)
  if(res)
    list_remove(paths "${path}")
    shell_path_set(${paths})
    return(true)
  else()
    return(false)
  endif()

endfunction()






function(shell_path_set)
  set(args ${ARGN})
  if(WIN32)
    string(REPLACE "\\\\" "\\" args "${args}")
  endif()
  message("setting path ${args}")
  shell_env_set(Path "${args}")
  return()
endfunction()





# redirects the output of the specified shell to the result value of this function
function(shell_redirect code)
  fwrite_temp("" ".txt")
  ans(tmp_file)
  shell("${code}> \"${tmp_file}\"")
  fread("${tmp_file}")
  ans(res)
  file(REMOVE "${tmp_file}")
  return_ref(res)
endfunction()





# creates a shell script file containing the specified code and the correct extesion to execute
# with execute_process
function(shell_script_create path code)
  if(NOT ARGN)
    shell_get()
    ans(shell)
  else()
    set(shell "${ARGN}")
  endif()
  if("${shell}_" STREQUAL "cmd_")
    if(NOT "${path}" MATCHES "\\.bat$")
      set(path "${path}.bat")
    endif()
    set(code "@echo off\n${code}")
  elseif("${shell}_" STREQUAL "bash_")
    if(NOT "${path}" MATCHES "\\.sh$")
      set(path "${path}.sh")
    endif()
    set(code "#!/bin/bash\n${code}")
    touch("${path}")
    execute_process(COMMAND chmod +x "${path}")
  else()
    message(WARNING "shell not supported: '${shell}' ")
    return()
  endif()
    fwrite("${path}" "${code}")
    return_ref(path)
endfunction()






# creates a temporary script file which contains the specified code
# and has the correct exension to be run with execute_process
# the path to the file will be returned
function(shell_tmp_script code)
  shell_get_script_extension()
  ans(ext)
  fwrite_temp("${code}" ".${ext}")
  ans(tmp)
  shell_script_create("${tmp}" "${code}")
  ans(res)
  return_ref(res)
endfunction()





# fully qualifies the path into a unix path (even windows paths)
# transforms C:/... to /C/...
function(unix_path path)
  path("${path}")
  ans(path)
  string(REGEX REPLACE "^_([a-zA-Z]):\\/" "/\\1/" path "_${path}")
  return_ref(path)
endfunction()




function(queue_isempty stack)
  map_tryget("${stack}" front)
  ans(front)
  map_tryget("${stack}" back)
  ans(back)
  math(EXPR res "${back} - ${front}")
  if(res)
    return(false)
  endif()  
  return(true)
endfunction()





  function(queue_new)
    address_new(queue)
    ans(queue)
    map_set_hidden(${queue} front 0)
    map_set_hidden(${queue} back 0)
    return(${queue})
  endfunction()





  function(queue_peek queue)
    map_tryget("${queue}" front)
    ans(front)
    map_tryget("${queue}" back)
    ans(back)
    if(${front} LESS ${back} )
      map_tryget("${queue}" "${front}")
      return_ans()
    endif()
    return()
  endfunction()





function(queue_pop queue)
  map_tryget("${queue}" front)
  ans(front)
  map_tryget("${queue}" back)
  ans(back)

  if(${front} LESS ${back})
    map_tryget("${queue}" "${front}")
    ans(res)
    math(EXPR front "${front} + 1")
    map_set_hidden("${queue}" "front" "${front}")
    return_ref(res)
  endif()
  return()
 endfunction()






  function(queue_push queue)
    map_tryget("${queue}" back)
    ans(back)
    map_set_hidden("${queue}" "${back}" "${ARGN}")
    math(EXPR back "${back} + 1")
    map_set_hidden("${queue}" back "${back}")
    
  endfunction()




function(rlist_new)
    address_new(rlist)
    ans(rlist)
    map_set_hidden(${queue} front 0)
    map_set_hidden(${queue} back 0)
    return(${queue})
endfunction()







# returns the specified element of the stack
function(stack_at stack idx)
  map_tryget("${stack}" back)
  ans(current_index)
  math(EXPR idx "${idx} + 1")
  if("${current_index}" LESS "${idx}")
    return()
  endif()
  map_tryget("${stack}" "${idx}")
  return_ans()
endfunction()






# returns all elements of the stack possibly fucking up
# element count because single elements may be lists-
# -> lists are flattened
function(stack_enumerate stack)
  map_tryget("${stack}" back)
  ans(current_index)
  if(NOT current_index)
    return()
  endif()
  
 # math(EXPR current_index "${current_index} - 1")
  set(res)
  foreach(i RANGE 1 ${current_index})
    map_tryget("${stack}" "${i}")
    ans(current)
    list(APPEND res "${current}")
  endforeach()
  return_ref(res)
endfunction()






  function(stack_isempty stack)
    map_tryget("${stack}" back)
    ans(count)
    if(count)
      return(false)
    endif()
    return(true)
  endfunction()





  function(stack_new)
    address_new(stack)
    ans(stack)   
    map_set_hidden("${stack}" front 0)
    map_set_hidden("${stack}" back 0)
    return(${stack})
  endfunction()





  function(stack_peek stack)
    map_tryget("${stack}" back)
    ans(back)
    map_tryget("${stack}" "${back}")
    return_ans()
  endfunction()





function(stack_pop stack)
  map_tryget("${stack}" back)
  ans(current_index)
  if(NOT current_index)
    return()
  endif()
  map_tryget("${stack}" "${current_index}")
  ans(res)
  math(EXPR current_index "${current_index} - 1")
  map_set_hidden("${stack}" back "${current_index}")
  return_ref(res)
endfunction()





function(stack_push stack)
  map_tryget("${stack}" back)
  ans(current_index)
  
  # increase stack pointer
  if(NOT current_index)
    set(current_index 0)
  endif()
  math(EXPR current_index "${current_index} + 1")
  map_set_hidden("${stack}" back "${current_index}")

  map_set_hidden("${stack}" "${current_index}" "${ARGN}")
endfunction()






  function(ascii_char code)
    ascii_generate_table()
    map_tryget(ascii_table "${code}")
    return_ans()
  endfunction()

 ## faster version
  function(ascii_char code)
    string(ASCII "${code}" res)
    return_ref(res)
  endfunction()





  function(ascii_code char)
    generate_ascii_table()
    map_tryget(ascii_table "'${char}'")
    return_ans()
  endfunction()




## generates the ascii table and stores it in the global ascii_table variable  
  function(ascii_generate_table)
    foreach(i RANGE 1 255)
      string(ASCII ${i} c)
      map_set(ascii_table "'${char}'" "${i}")
      map_set(ascii_table "${i}" "${char}")
    endforeach()
    function(ascii_generate_table)
    endfunction()
  endfunction()






## **`delimiters()->[delimiter_begin, delimiter_end]`**
##
## parses delimiters and retruns a list of length 2 containing the specified delimiters. 
## The usefullness of this function becomes apparent when you use [string_take_delimited](#string_take_delimited)
## 
##
function(delimiters)
  set(delimiters ${ARGN})


  if("${delimiters}_" STREQUAL "_")
    set(delimiters \")
  endif()



  list_pop_front(delimiters)
  ans(delimiter_begin)


  if("${delimiter_begin}" MATCHES ..)
    string(REGEX REPLACE "(.)(.)" "\\2" delimiter_end "${delimiter_begin}")
    string(REGEX REPLACE "(.)(.)" "\\1" delimiter_begin "${delimiter_begin}")
  else()
    list_pop_front(delimiters)
    ans(delimiter_end)
  endif()

  
  if("${delimiter_end}_" STREQUAL "_")
    set(delimiter_end "${delimiter_begin}")
  endif()

  return(${delimiter_begin} ${delimiter_end})
endfunction()




  function(cmake_string_escape str)
    string(REPLACE "\\" "\\\\" str "${str}")
    string(REPLACE "\"" "\\\"" str "${str}")
    string(REPLACE "(" "\\(" str "${str}")
    string(REPLACE ")" "\\)" str "${str}")
    string(REPLACE "$" "\\$" str "${str}") 
    string(REPLACE "#" "\\#" str "${str}") 
    string(REPLACE "^" "\\^" str "${str}") 
    string(REPLACE "\t" "\\t" str "${str}")
    string(REPLACE ";" "\\;" str "${str}")
    string(REPLACE "\n" "\\n" str "${str}")
    string(REPLACE "\r" "\\r" str "${str}")
    #string(REPLACE "\0" "\\0" str "${str}") unnecessary because cmake does not support nullcahr in string
    string(REPLACE " " "\\ " str "${str}")
    return_ref(str)
  endfunction()






  function(cmake_string_unescape str)
    string(REPLACE "\\\"" "\"" str "${str}")
    string(REPLACE "\\\\" "\\" str "${str}")
    string(REPLACE "\\(" "(" str "${str}")
    string(REPLACE "\\)" ")" str "${str}")
    string(REPLACE "\\$" "$" str "${str}")
    string(REPLACE "\\#" "#" str "${str}")
    string(REPLACE "\\^" "^" str "${str}")
    string(REPLACE "\\t" "\t" str "${str}")
    string(REPLACE "\\;" ";"  str "${str}")
    string(REPLACE "\\n" "\n" str "${str}")
    string(REPLACE "\\r" "\r" str "${str}")
    string(REPLACE "\\0" "" str "${str}") ## not supported  in cmake strings
    string(REPLACE "\\ " " " str "${str}")
    return_ref(str)
  endfunction()




## `(<any>)-><bool>`
##
## returns true if the specified value is an encoded list
## meaning that it needs to be decoded before it will be correct
function(is_encoded_list)
  string_codes()
  eval("
    function(is_encoded_list)
      if(\"\${ARGN}\" MATCHES \"[${bracket_open_code}${bracket_close_code}${semicolon_code}]\")
        set(__ans true PARENT_SCOPE)
      else()
        set(__ans false PARENT_SCOPE)
      endif()

    endfunction()
  ")
  is_encoded_list(${ARGN})
  return_ans()
endfunction()







# decodes encoded brakcets in a string
function(string_decode_bracket str)
    string_codes()
    string(REPLACE "${bracket_open_code}" "["  str "${str}") 
    string(REPLACE "${bracket_close_code}" "]"  str "${str}")
    return_ref(str)
endfunction()





# decodes an encoded empty string
function(string_decode_empty str) 
    string_codes()
  if("${str}" STREQUAL "${empty_code}")
    return("")
  endif()
  return_ref(str)
endfunction()






# decodes an encoded list
  function(string_decode_list str)
    string_decode_semicolon("${str}")
    ans(str)
    string_decode_bracket("${str}")
    ans(str)
    string_decode_empty("${str}")
    ans(str)
   # message("decoded3: ${str}")
    return_ref(str)
  endfunction()


## faster
function(string_decode_list str)
  string_codes()
  eval("
  function(string_decode_list str)
    string(REPLACE \"${bracket_open_code}\" \"[\"  str \"\${str}\")
    string(REPLACE \"${bracket_close_code}\" \"]\"  str \"\${str}\")
    string(REPLACE \"${semicolon_code}\" \";\"  str \"\${str}\")
    set(__ans \"\${str}\" PARENT_SCOPE)
  endfunction()
  ")
  string_decode_list("${str}")
  return_ans()
endfunction()




#decodes parentheses in a string
function(string_decode_parentheses str)
    string_codes()
  string(REPLACE "${paren_open_code}" "\(" str "${str}")
  string(REPLACE "${paren_close_code}" "\)" str "${str}")
  return_ref(str)
endfunction()






# decodes semicolons in a string
  function(string_decode_semicolon str)
    string(ASCII  31 semicolon_code)
    string(REPLACE "${semicolon_code}" ";" str "${str}")
    return_ref(str)
  endfunction()



## faster
  function(string_decode_semicolon str)
    string_codes()
    eval("
      function(string_decode_semicolon str)
        string(REPLACE  \"${semicolon_code}\" \";\" str \"\${str}\" )
        set(__ans \"\${str}\" PARENT_SCOPE)
      endfunction()
    ")
    string_decode_semicolon("${str}")
    return_ans()
  endfunction()





# encodes brackets
function(string_encode_bracket str)
  string_codes()
  string(REPLACE "[" "${bracket_open_code}" str "${str}") 
  string(REPLACE "]" "${bracket_close_code}" str "${str}")
  return_ref(str)
endfunction()






## escapes a string to be delimited
## by the the specified delimiters
function(string_encode_delimited str)
    delimiters(${ARGN})
    ans(ds)
    list_pop_front(ds)
    ans(delimiter_begin)
    list_pop_front(ds)
    ans(delimiter_end)

    string(REPLACE \\ \\\\ str "${str}" )
    string(REPLACE "${delimiter_end}" "\\${delimiter_end}" str "${str}" )
    set(str "${delimiter_begin}${str}${delimiter_end}")
    return_ref(str)
endfunction()





# encodes an empty element
function(string_encode_empty str)
  message("huh")
  string_codes()

  if("_${str}" STREQUAL "_")
    return("${empty_code}")
  endif()
  return_ref(str)
endfunction()









# encodes a string list so that it can be correctly stored and retrieved
function(string_encode_list str)
  string_codes()
  string(REPLACE "[" "${bracket_open_code}" str "${str}")
  string(REPLACE "]" "${bracket_close_code}" str "${str}")
  string(REPLACE ";" "${semicolon_code}" str "${str}")
  set(__ans "${str}" PARENT_SCOPE)
endfunction()

## faster
function(string_encode_list str)
  string_codes()
  eval("
    function(string_encode_list str)
    string(REPLACE \"[\" \"${bracket_open_code}\" str \"\${str}\")
    string(REPLACE \"]\" \"${bracket_close_code}\" str \"\${str}\")
    string(REPLACE \";\" \"${semicolon_code}\" str \"\${str}\")
    set(__ans \"\${str}\" PARENT_SCOPE)
  endfunction()
  ")
  string_encode_list("${str}")
  return_ans()
endfunction()








# encodes parentheses in a string
  function(string_encode_parentheses str)
    string_codes()
    string(REPLACE "\(" "${paren_open_code}" str "${str}")
    string(REPLACE "\)" "${paren_close_code}" str "${str}")
    return_ref(str)
  endfunction()







# encodes semicolons with seldomly used utf8 chars.
# causes error for string(SUBSTRING) command
  function(string_encode_semicolon str)
    # make faster by checking if semicolon exists?
    string(ASCII  31 semicolon_code)
    # string(FIND "${semicolon_code}" has_semicolon)
    #if(has_semicolon GREATER -1) replace ...

    string(REPLACE ";" "${semicolon_code}" str "${str}" )
    return_ref(str)
  endfunction()


## faster
  function(string_encode_semicolon str)
    string_codes()
    eval("
      function(string_encode_semicolon str)
        string(REPLACE \";\" \"${semicolon_code}\" str \"\${str}\" )
        set(__ans \"\${str}\" PARENT_SCOPE)
      endfunction()
    ")
    string_encode_semicolon("${str}")
    return_ans()
  endfunction()







  function(argument_escape arg)
    cmake_string_escape("${arg}")
    ans(arg)
    return_ref(arg)
    if("${arg}_" MATCHES "(^_$)|(;)|(\")")
      set(arg "\"${arg}\"") 
    endif()
    return_ref(arg)
  endfunction()




## [**`format(<template string>)-><string>`**](<%="${template_path}"%>)
##
## this function utilizes [`assign(...)`](#assign) to evaluate expressions which are enclosed in handlebars: `{` `}`
## 
##
## *Examples*
## ```cmake
## # create a object
## obj("{a:1,b:[2,3,4,5,6],c:{d:3}}")
## ans(data)
## ## use format to print navigated expressiosn:
## format("{data.a} + {data.c.d} = {data.b[2]}") => "1 + 3 = 4"
## format("some numbers: {data.b[2:$]}") =>  "some numbers: 4;5;6"
## ...
## ```
## *Note:* You may not use ASCII-29 since it is used interally in this function. If you don't know what this means - don't worry
## 
##
function(format)
  string(ASCII 29 delimiter)
  set(template "${ARGN}")
  string(REGEX MATCHALL "{[^}]*}" matches "${template}")
  list_remove_duplicates(matches)
  foreach(match ${matches})
    string(REGEX REPLACE "^{(.*)}$" "\\1" match "${match}")
    assign(value = ${match})
    string(REPLACE "{${match}}" "${value}" template "${template}")
  endforeach()
  return_ref(template)
endfunction()






# matches the first occurens of regex and returns it
function(regex_search str regex)
  string(REGEX MATCH "${regex}" res "${str}")  
  return_ref(res)
endfunction()





  function(string_append_line_indented str_ref what)
    indent("${what}" ${ARGN})
    ans(indented)
    set("${str_ref}" "${${str_ref}}${indented}\n" PARENT_SCOPE)
  endfunction()





## <%=markdown_template_function_header("(<index:int> <input:string>)-><char>")%>
##
## returns the character at the position specified. strings are indexed 0 based
## indices less than -1 are translated into length - |index|
##
## *Examples*
## ```cmake
## string_char_at(3 "abcdefg")  # => "d"
## string_char_at(-3 "abcdefg") # => "f"
## ```
##
function(string_char_at index input)
  string(LENGTH "${input}" len)
  string_normalize_index("${input}" ${index})
  ans(index)
  if("${index}" LESS 0 OR ${index} EQUAL "${len}" OR ${index} GREATER ${len}) 
    return()
  endif()
  string(SUBSTRING "${input}" ${index} 1 res)
  return_ref(res)

endfunction()




# special chars |||||||↔|†|‡
macro(string_codes)
  string(ASCII 14 "${ARGN}free_token1")
  string(ASCII 15 "${ARGN}free_token2")
  string(ASCII 1 "${ARGN}free_token3")
  string(ASCII 2 "${ARGN}free_token4")

  string(ASCII 29 "${ARGN}bracket_open_code")
  string(ASCII 28 "${ARGN}bracket_close_code")
  string(ASCII 30 "${ARGN}ref_token")
  string(ASCII 21 "${ARGN}free_token")
  string(ASCII 31 "${ARGN}semicolon_code")
  string(ASCII 24 "${ARGN}empty_code")
  string(ASCII 2  "${ARGN}paren_open_code")
  string(ASCII 3  "${ARGN}paren_close_code")
  set("${ARGN}identifier_token" "__")
endmacro()

function(string_codes_print)
  string_codes()
  print_vars("bracket_open_code")
  print_vars("bracket_close_code")
  print_vars("ref_token")
  print_vars("semicolon_code")
  print_vars("empty_code")
  print_vars("paren_open_code")
  print_vars("paren_close_code")
endfunction()





## combines the varargs into a string joining them with separator
## e.g. string_combine(, a b c) => "a,b,c"
function(string_combine separator )
  set(first true)
  set(res)
  foreach(arg ${ARGN})
    if(first )
      set(first false)
    else()
      set(res "${res}${separator}")
    endif()
    set(res "${res}${arg}")
  endforeach()
  return_ref(res)
endfunction()





  function(string_concat)
    string(CONCAT ans ${ARGN})
    return_ref(ans)
  endfunction()




# returns true if ${str} contains ${search}
function(string_contains str search)
  string(FIND "${str}" "${search}" index)
  if("${index}" LESS 0)
    return(false)
  endif()
  return(true)
endfunction()




## tries to parse a delimited string
## returns either the original or the parsed delimited string
## delimiters can be specified via varargs
## see also string_take_delimited
function(string_decode_delimited str)
  string_take_delimited(str ${ARGN})
  ans(res)
  if("${res}_" STREQUAL "_")
    return_ref(str)
  endif()
  return_ref(res)
endfunction()




# returns true iff str ends with search
function(string_ends_with str search)
  string(FIND "${str}" "${search}" out REVERSE)
  if(${out} EQUAL -1)
  return(false)
  endif()
  string(LENGTH "${str}" len)
  string(LENGTH "${search}" len2)
  math(EXPR out "${out}+${len2}")
  if("${out}" EQUAL "${len}")
    return(true)
  endif()
  return(false)
endfunction()




## evaluates the string <str> in the current scope
## this is done by macro variable expansion
## evaluates both ${} and @@ style variables
macro(string_eval str)
  set_ans("${str}")
endmacro()





  function(string_find str substr)
    set(args ${ARGN})
    list_extract_labelled_keyvalue(args --reverse REVERSE)
    ans(reverse)
    string(FIND "${str}" "${substr}" idx ${reverse})
    return_ref(idx)
  endfunction()




## returns true if the given string is empty
## normally because cmake evals false, no,  
## which destroys tests for real emtpiness
##
##
 function(string_isempty  str)    
    if( "_" STREQUAL "_${str}" )
      return(true)
    endif()
    return(false)
 endfunction()




## returns true if the string is a integer (number)
## does not match non integers
function(string_isnumeric str)
  if("_${str}" MATCHES "^_[0-9]+$")
    return(true)
  endif()
  return(false)
endfunction()





  function(string_length str)
    string(LENGTH "${str}" len)
    return_ref(len)
  endfunction()




  #splits the specified string into lines
  ## normally the string would have to be semicolon encoded
  ## to correctly display lines with semicolons 
  function(string_lines input)      
    string_split("${input}" "\n" ";" )
    #string(REPLACE "\n" ";" input "${input}")
    return_ans(lines)
  endfunction()






# evaluates the string against the regex
# and returns true iff it matches
function(string_match  str regex)
  if("${str}" MATCHES "${regex}")
    return(true)
  endif()
  return(false)
endfunction()




# replaces all non alphanumerical characters in a string with an underscore
function(string_normalize input)
	string(REGEX REPLACE "[^a-zA-Z0-9_]" "_" res "${input}")
	return_ref(res)
endfunction()




# normalizes the index of str (negativ indices are transformed into positive onces)
function(string_normalize_index str index)

  set(idx ${index})
  string(LENGTH "${str}" length)
  if(${idx} LESS 0)
    math(EXPR idx "${length} ${idx} + 1")
  endif()
  if(${idx} LESS 0)
    #message(WARNING "index out of range: ${index} (${idx}) length of string '${str}': ${length}")
    return(-1)
  endif()

  if(${idx} GREATER ${length})
    #message(WARNING "index out of range: ${index} (${idx}) length of string '${str}': ${length}")
    return(-1)
  endif()
  return(${idx})
endfunction()




# returns the the parts of the string that overlap
# e.g. string_overlap(abcde abasd) returns ab
function(string_overlap lhs rhs)
  string(LENGTH "${lhs}" lhs_length)
  string(LENGTH "${rhs}" rhs_length)

  math_min("${lhs_length}" "${rhs_length}")
  ans(len)



  math(EXPR last "${len}-1")

  set(result)

  foreach(i RANGE 0 ${last})
    string_char_at(${i} "${lhs}")
    ans(l)
    string_char_at(${i} "${rhs}")
    ans(r)
    if("${l}" STREQUAL "${r}")
      set(result "${result}${l}")
    else()
      break()
    endif()
  endforeach()
  return_ref(result)

endfunction()





## pads the specified string to be as long as specified
## if the string is longer then nothing is padded
## if no delimiter is specified than " " (space) is used
## if --prepend is specified the padding is inserted into front of string
function(string_pad str len)  
  set(delimiter ${ARGN})
  list_extract_flag(delimiter --prepend)
  ans(prepend)
  if("${delimiter}_" STREQUAL "_")
    set(delimiter " ")
  endif()  
  string(LENGTH "${str}" actual)  
  if(${actual} LESS ${len})

    math(EXPR n "${len} - ${actual}") 

    string_repeat("${delimiter}" ${n})
    ans(padding)
    
    if(prepend)
      set(str "${padding}${str}")
    else()
      set(str "${str}${padding}")    
    endif()    
  endif()
  return_ref(str)
endfunction()





  function(string_random)
    set(args ${ARGN})
    message(FATAL_ERROR "not implemented")    
  endfunction()





# escapes chars used by regex
  function(string_regex_escape str)
  #  string(REGEX REPLACE "(\\/|\\]|\\.|\\[|\\*)" "\\\\\\1" str "${str}")
  ## regex chars \ / ] [ ( ) * . - ^ $ ?
    string(REGEX REPLACE "(\\/|\\]|\\.|\\[|\\*|\\$|\\^|\\-|\\+|\\?)" "\\\\\\1" str "${str}")
    return_ref(str)
  endfunction()





# removes the beginning of a string
function(string_remove_beginning original beginning)
  string(LENGTH "${beginning}" len)
  string(SUBSTRING "${original}" ${len} -1 original)
  return_ref(original)
endfunction()




# removes the back of a string
function(string_remove_ending original ending)
  string(LENGTH "${ending}" len)
  string(LENGTH "${original}" orig_len)
  math(EXPR len "${orig_len} - ${len}")
  string(SUBSTRING "${original}" 0 ${len} original)
  return_ref(original)
  endfunction()





  # repeats ${what} and separates it by separator
  function(string_repeat what n)
    set(separator "${ARGN}")
    set(res)
    if("${n}" LESS 1)
      return()
    endif()
    foreach(i RANGE 1 ${n})
      if(NOT ${i} EQUAL 1)
        set(res "${separator}${res}")
      endif()
      set(res "${res}${what}")
    endforeach()
    return_ref(res)
  endfunction()





#replaces all occurrences of pattern with replace in str and returns str
function(string_replace str pattern replace)
  string(REPLACE "${pattern}" "${replace}" res "${str}")
  return_ref(res)
endfunction()




# replaces first occurence of stirng_search with string_replace in string_input
function(string_replace_first  string_search string_replace string_input)
	string(FIND "${string_input}" "${string_search}" index)
	if("${index}" LESS "0")
		return_ref(string_input)
	endif()
	string(LENGTH "${string_search}" search_length)
	string(SUBSTRING "${string_input}" "0" "${index}" part1)
	math(EXPR index "${index} + ${search_length}")
	string(SUBSTRING "${string_input}" "${index}" "-1" part2)
	set(res "${part1}${string_replace}${part2}")
	return_ref(res)
endfunction()





## shortens the string to be at most max_length long
  function(string_shorten str max_length)
    set(shortener "${ARGN}")
    if(shortener STREQUAL "")
      set(shortener "...")
    endif()

    string(LENGTH "${str}" str_len)
    string(LENGTH shortener shortener_len)
    math(EXPR combined_len "${str_len} + ${shortener_len}")

    if(NOT str_len GREATER "${max_length}")
      return_ref(str)
    endif()

    math(EXPR max_length "${max_length} - ${shortener_len}")

    string_slice("${str}" 0 ${max_length})
    ans(res)
    set(res "${res}${shortener}")
    return_ref(res)
  endfunction()






# extracts a portion of the string negative indices translatte to count fromt back
function(string_slice str start_index end_index)
  # indices equal => select nothing

  string_normalize_index("${str}" ${start_index})
  ans(start_index)
  string_normalize_index("${str}" ${end_index})
  ans(end_index)

  if(${start_index} LESS 0)
    message(FATAL_ERROR "string_slice: invalid start_index ")
  endif()
  if(${end_index} LESS 0)
    message(FATAL_ERROR "string_slice: invalid end_index")
  endif()
  # copy array
  set(result)
  math(EXPR len "${end_index} - ${start_index}")
  string(SUBSTRING "${str}" ${start_index} ${len} result)

  return_ref(result)
endfunction()
  




# splits a string by regex storing the resulting list in ${result}
#todo: this should also handle strings containing 
function(string_split  string_subject split_regex)
	string(REGEX REPLACE ${split_regex} ";" res "${string_subject}")
  return_ref(res)
endfunction()





# splits input at first occurence of separator into part a  and partb
function(string_split_at_first parta partb input separator)
  string(FIND "${input}" "${separator}" idx )
  if(${idx} LESS 0)
    set(${parta} "${input}" PARENT_SCOPE)
    set(${partb} "" PARENT_SCOPE)
    return()
  endif()

  string(SUBSTRING "${input}" 0 ${idx} pa)
  math(EXPR idx "${idx} + 1")

  string(SUBSTRING "${input}" ${idx} -1 pb)
  set(${parta} ${pa} PARENT_SCOPE)
  set(${partb} ${pb} PARENT_SCOPE)
endfunction()




  #splits string at last occurence of separator and retruns both parts
  function(string_split_at_last parta partb input separator)
    string(FIND "${input}" "${separator}" idx  REVERSE)
    if(${idx} LESS 0)
      set(${parta} "${input}" PARENT_SCOPE)
      set(${partb} "" PARENT_SCOPE)
      return()
    endif()

    string(SUBSTRING "${input}" 0 ${idx} pa)
    math(EXPR idx "${idx} + 1")

    string(SUBSTRING "${input}" ${idx} -1 pb)
    set(${parta} ${pa} PARENT_SCOPE)
    set(${partb} ${pb} PARENT_SCOPE)
  endfunction()




  function(string_split_parts str length)
    address_new()
    ans(first_node)
    
    set(current_node ${first_node})
    while(true)      
      string(LENGTH "${str}" len)       
      if(${len} LESS ${length})
        address_set(${current_node} "${str}")
        set(str)
      else()
        string(SUBSTRING "${str}" 0 "${length}" part)
        string(SUBSTRING "${str}" "${length}" -1 str)
        address_set(${current_node} "${part}")
      endif()
      if(str)
        address_new()
        ans(new_node)
        map_set_hidden(${current_node} next ${new_node})
        set(current_node ${new_node})
      else()
        return_ref(first_node)
      endif()     
      
    endwhile()

  endfunction()




# returns true if str starts with search
function(string_starts_with str search)
  string(FIND "${str}" "${search}" out)
  if("${out}" EQUAL 0)
    return(true)
  endif()
  return(false)
endfunction()




# wraps the substring command
# optional parameter end 
function(string_substring str start)
  set(len ${ARGN})
  if(NOT len)
    set(len -1)
  endif() 
  string_normalize_index("${str}" "${start}")
  ans(start)

  string(SUBSTRING "${str}" "${start}" "${len}" res)
  return_ref(res)
endfunction()




# remove match from in out var ${${str_name}}
# returns match
function(string_take str_name match)
  string(FIND "${${str_name}}" "${match}" index)
  #message("trying to tak ${match}")
  if(NOT ${index} EQUAL 0)
    return()
  endif()
  #message("took ${match}")
  string(LENGTH "${match}" len)
  string(SUBSTRING "${${str_name}}" ${len} -1 rest )
  set("${str_name}" "${rest}" PARENT_SCOPE)


  return_ref(match)
 
endfunction()





## string_take_address
##
## takes an address from the string ref  
function(string_take_address str_ref)
  string_take_regex("${str_ref}" ":[1-9][0-9]*")
  ans(res)
  set(${str_ref} ${${str_ref}} PARENT_SCOPE)   
  return_ref(res)
endfunction()





## takes a string which is delimited by any of the specified
## delimiters 
## string_take_any_delimited(<string&> <delimiters:<delimiter...>>)
  function(string_take_any_delimited str_ref)
    foreach(delimiter ${ARGN})
      string(LENGTH "${${str_ref}}" l1)
      string_take_delimited(${str_ref} "${delimiter}")
      ans(match)
      string(LENGTH "${${str_ref}}" l2)
      if(NOT "${l1}" EQUAL "${l2}")
        set("${str_ref}" "${${str_ref}}" PARENT_SCOPE)
        return_ref(match)
      endif()

    endforeach()
    return()
  endfunction()





## if the beginning of the str_name is a delimited string
## the undelimited string is returned  and removed from str_name
## you can specify the delimiter (default is doublequote "")
## you can also specify begin and end delimiter 
## the delimiters may only be one char 
## the delimiters are removed from the result string
## escaped delimiters are unescaped
function(string_take_delimited __string_take_delimited_string_ref )
  regex_delimited_string(${ARGN})
  ans(__string_take_delimited_regex)
  string_take_regex(${__string_take_delimited_string_ref} "${__string_take_delimited_regex}")
  ans(__string_take_delimited_match)
  if(NOT __string_take_delimited_match)
    return()
  endif()
  set("${__string_take_delimited_string_ref}" "${${__string_take_delimited_string_ref}}" PARENT_SCOPE)

  # removes the delimiters
  string_slice("${__string_take_delimited_match}" 1 -2)
  ans(res)
  # unescape string
  string(REPLACE "\\${delimiter_end}" "${delimiter_end}" res "${res}")
  return_ref(res) 
endfunction()

## faster version
function(string_take_delimited __str_ref )
  set(input "${${__str_ref}}")

  regex_delimited_string(${ARGN})
  ans(regex)
  if("${input}" MATCHES "^${regex}")
    string(LENGTH "${CMAKE_MATCH_0}" len)
    if(len)
      string(SUBSTRING "${input}" ${len} -1 input )
    endif()
    string(REPLACE "\\${delimiter_end}" "${delimiter_end}" res "${CMAKE_MATCH_1}")
    set("${__str_ref}" "${input}" PARENT_SCOPE)
    set(__ans "${res}" PARENT_SCOPE)
  else()
    set(__ans PARENT_SCOPE)
  endif()

endfunction()






# tries to match the regex at the begging of ${${str_name}} and returns the match
# ${str_name} is shortened in the process
# match is returned
function(string_take_regex str_name regex)
  string(REGEX MATCH "^(${regex})" match "${${str_name}}")
  string(LENGTH "${match}" len)
  if(len)
    string(SUBSTRING "${${str_name}}" ${len} -1 res )
    set(${str_name} "${res}" PARENT_SCOPE)
    return_ref(match)
  endif()
  return()
endfunction()

## fasterversion does not work in case of nested regex parenthesis
## and unknown matchgroup of rest string
# function(string_take_regex str_name regex)
#   if("${${str_name}}" MATCHES "^(${regex})(.*)$")
#     set(${str_name} "${CMAKE_MATCH_2}" PARENT_SCOPE)
#     set(__ans "${CMAKE_MATCH_1}" PARENT_SCOPE)
    
#     endif()
#   else()
#     set(__ans PARENT_SCOPE)
#   endif()



# endfunction()


## fasterversion
## also does not work.... 
# function(string_take_regex str_name regex)
#   if("${${str_name}}" MATCHES "^(${regex})")
#     set(__ans "${CMAKE_MATCH_1}" PARENT_SCOPE)
#     string(REGEX REPLACE "^(${regex})" "" "${str_name}" "${${str_name}}")
#     set(${str_name} "${${str_name}}" PARENT_SCOPE)    
#   else()
#     set(__ans PARENT_SCOPE)
#   endif()
# endfunction()




function(string_take_regex_replace str_name regex replace)
  string_take_regex(${str_name} "${regex}")
  ans(match)
  if("${match}_" STREQUAL _)
    return()
  endif()
  set(${str_name} "${${str_name}}" PARENT_SCOPE)
  string(REGEX REPLACE "${regex}" "${replace}" match "${match}")
  return_ref(match)
endfunction()








function(string_take_whitespace __string_take_whitespace_string_ref)
  string_take_regex("${__string_take_whitespace_string_ref}" "[ ]+")
  ans(__string_take_whitespace_res)
  set("${__string_take_whitespace_string_ref}" "${${__string_take_whitespace_string_ref}}" PARENT_SCOPE)
  return_ref(__string_take_whitespace_res)
endfunction()


## faster
macro(string_take_whitespace __str_ref)
  if("${${__str_ref}}" MATCHES "^([ ]+)(.*)")
    set(__ans "${CMAKE_MATCH_1}")
    set(${__str_ref} "${CMAKE_MATCH_2}")
  else()
    set(__ans)
  endif()
endmacro()







# transforms the specifiedstring to lower case
function(string_tolower str)
  string(TOLOWER "${str}" str)
  return_ref(str)
endfunction()





  function(string_toupper str)
    string(TOUPPER "${str}" str)
    return_ref(str)
  endfunction()




function(string_trim str)
  string(STRIP "${str}" str)
  return_ref(str)
endfunction()




## removes the beginning of the string that matches
## from ref lhs and ref rhs
function(string_trim_to_difference lhs rhs)
  string_overlap("${${lhs}}" "${${rhs}}")
  ans(overlap)

  string_take(${lhs} "${overlap}")
  string_take(${rhs} "${overlap}")
  set("${lhs}" "${${lhs}}" PARENT_SCOPE)
  set("${rhs}" "${${rhs}}" PARENT_SCOPE)
endfunction()







  function(task_run_all)
    set(completed_tasks)
    while(true)
      task_run_next()
      ans(completed_task)
      if(completed_task)
        list(APPEND completed_tasks ${completed_task})
      else()
        break()
      endif()
    endwhile()
    return_ref(completed_tasks)
  endfunction()






# invokes a single task
function(task_run_next)
  address_get(__initial_invoke_later_list)
  ans(tasks)
  foreach(task ${tasks})
    string_decode_semicolon("${task}")
    ans(task)
    task_enqueue("${task}")
  endforeach()

  function(task_run_next)
    map_tryget(global task_current)
    ans(task_running)
    if(task_running)
      return()
    endif()

    map_pop_front(global task_queue)
    ans(task)

    if(NOT task)
      return()
    endif()
    map_tryget(${task} arguments)
    ans(arguments)
    map_tryget(${task} callback)
    ans(callback)
    set(this ${task})

    map_set(${task} state "running")
    map_set(global task_current ${task})
    
    eval("${callback}(${arguments})")
    ans(result)
    map_set(${task} result "${result}")
    map_set(${task} state "complete")
    map_set(global task_current)

    return_ref(task)
  endfunction()
  task_run_next()
  return_ans()
endfunction()






function(markdown_compile_function file)
  path_qualify(file)
  if(NOT "${file}" MATCHES "(.+)\\.cmake")
    message(FATAL_ERROR "invalid file")
  endif()
  set(target "${CMAKE_MATCH_1}.md")
  markdown_template_function_descriptions(${file})
  ans(res)
  if(NOT res)
    return()
  endif()
  fwrite("${target}" "${res}")
  return()
endfunction()




function(markdown_include_sourcecode path)
  path("${path}")
  ans(qualified_path)
  if(EXISTS "${qualified_path}")  
    fread("${path}")
    ans(res)
    else()
      set(res "<file does not exist>")
    endif()
    set(res "*${path}*: \n```${ARGN}\n${res}\n```")
    return_ref(res)
endfunction()






function(markdown_link id name)
  ## get link
  return("[${name}](#${id})")  
endfunction()




  function(markdown_section id name)
    return("## <a name=\"${id}\"></a> ${name}")
  endfunction()






function(markdown_see_function function_sig)
  if("${function_sig}" MATCHES "^([a-zA-Z0-9_]+)[ \\t]*\\(")
    set(function_name "${CMAKE_MATCH_1}")

    return("[`${function_sig}`](#${function_name})")
  endif()
  return()
endfunction()




function(markdown_template_function_descriptions)
  set(res)
  foreach(template_path ${ARGN})
      fread("${template_path}")
      ans(content)
      cmake_script_comment_header("${content}")
      ans(comments)
      cmake_script_parse("${content}" --first-function-header)
      ans(function_def)
      assign(function_name = function_def.function_args[0])
      if(NOT "${function_name}_" STREQUAL "_")
        get_filename_component(template_dir "${template_path}" PATH)
        pushd("${template_dir}")
          template_run("${comments}")
          ans(comments)
        popd()
        set(res "${res}## <a name=\"${function_name}\"></a> `${function_name}`\n\n${comments}\n\n\n\n")
      endif()
  endforeach()
  return_ref(res)
endfunction()








function(markdown_template_function_header signature)
assign(function_name = function_def.function_args[0])

return("[**`${function_name}${signature}`**](${template_path})")
endfunction()





function(markdown_template_function_list )
  set(function_list)
  foreach(file ${ARGN})
    cmake_script_parse_file(${file} --first-function-header)
    ans(function_def)
    assign(function_name = function_def.function_args[0])
    set(function_list "${function_list}\n* [${function_name}](#${function_name})")
  endforeach()
  return_ref(function_list)
endfunction()




function(markdown_template_link file)
  path_qualify(file)
  path_relative("${root_template_dir}" "${file}")
  ans(relative_path)

  fread_lines("${file}" --limit-count 1 --regex "#+ .*")
  ans(title)

  string(REGEX REPLACE "#+ *(.*)" "\\1" title "${title}")
  return("[${title}](${relative_path})")
endfunction()







function(template_shell command)
    if("${command}" STREQUAL "set_base_dir")
        address_set(template_shell_base_dir "${ARGN}")
    endif()
    address_get(template_shell_base_dir)
    ans(shell_base_dir)
    if(NOT shell_base_dir)
        pwd()
        ans(shell_base_dir)
        address_set(template_shell_base_dir "${shell_base_dir}")
    endif()
    
    set(args ${ARGN})
    list_extract_flag(args --echo)
    ans(echo)
    pwd()
    ans(pwd)
    path_relative("${shell_base_dir}" "${pwd}")
    ans(rel_pwd)
    string_combine(" " ${args})
    ans(arg_string)
    template_out("${rel_pwd}/> ${command} ${arg_string}")
    call2("${command}" ${args})
    ans(res)
    if(NOT echo)
        return()
    endif()
    json_indented("${res}")
    ans(res)
    string(REPLACE "${shell_base_dir}" "." res "${res}")
    template_out("\n")
    template_out("${res}")
endfunction()





## `()-><void>`
## begins a new template after calling this inner template functions start
## to work (like template_out())
##
function(template_begin)
  address_new()
  ans(ref)
  set(__template_output_stream ${ref} PARENT_SCOPE)
endfunction()





## `()-><generated content:<string>>`
## ends the current template and returns the generated content
function(template_end)
  template_guard()
  address_get("${__template_output_stream}")
  return_ans()
endfunction()





##
## `()-><template output:<address>>`
##
## fails if not executed inside of a template else returns the 
## template output ref
##
function(template_guard)
  template_output_stream()
  ans(ref)
  if(NOT ref)
    message(FATAL_ERROR "call may only occure inside of a template")
  endif()  
  return(${ref})
endfunction()






## `(<string...>) -> <void>`
## 
## writes the specified string(s) to the templates output stream
## fails if not called inside a template
##
function(template_out)
  template_guard()
  ans(ref)
  address_append_string(${ref} "${ARGN}")
  return()
endfunction()






## `()-><template output stream:<address>>`
##
## returns the output ref for the template
##
function(template_output_stream)
 return(${__template_output_stream})
endfunction()




## `(<format string...?>-><void>`
##
## formats the specified string and and append it to the template output stream
##
function(template_out_format)
  format("${ARGN}")
  ans(res)
  template_out("${res}")
  return()
endfunction() 




## `(<structured data...>) -> <void>`
## 
## writes the serialized data to the templates output
## fails if not called inside a template
##
function(template_out_json)
  json_indented(${ARGN})
  ans(res)
  template_out("${res}")
  return()
endfunction()





## `(<input:<string>>)-><cmake code>`
##
##  
## creates and returns cmake code from specified template string
## the syntax is as follows
## * `<%%` `%%>` encloses cmake code
## * `<%%%` and `%%%>` escape `<%%` and `%%>` resp.
## * shorthands
##     * `<%%=` runs the function specified if possible (only single line function calls allowed) or formats the following nonspace string using the `format()` function (allows things like `<%%="${var} {format.expression[3].navigation.key}%%>`) 
##     * single line function calls are `func(.....)` but not `func(... \n ....)` 
##     * `@@<cmake function call>` is replaced with `<%%= <cmake function call> %%>`
##     * `@@<navigation expression>` is replaced with `<%%= {<navigation expression>}%%>`
##
## **Examples:**
## * assume `add(lhs rhs) => {lhs+rhs}`
## * assume `data = {a:1,b:[2,3,4],c:{d:5,b:[6,7,8]}}`
## * assume `data2 = "hello!"`
## * `@@@@` => `@@`
## * `<%%%` => `<%%`
## * `%%%>` => `%%>`
## * `@@data2` => `hello!`
## * `@@add(1 4)` => `5`
## * `@foreach(i RANGE 1 3)@i@endforeach()` => `123`
## * `<%%= ${data2} %%>` => `hello!`
## * `<%%= ${data2} ${data2} bye! %%>` => `hello!;hello!;bye!`
## * `<%%= "${data2} ${data2} bye!" %%>` => `hello! hello! bye!`
## * `<%%= add(1 4) %%> => `5`
## * `<%% template_out(hi) %%>` => `hi`
##
## **NOTE** *never use ascii 16 17 18 28 29 31* as these special chars are used internally
function(template_compile input)

  ## encode input
  set(delimiter_start "<%")
  set(delimiter_end "%>")
  set(delimiter_start_escape "<%%")
  set(delimiter_end_escape "%%>")
  set(shorthand_indicator "@")
  set(shorthand_indicator_escape "@@")


  string(ASCII 16 shorthand_indicator_code)
  string(ASCII 17 delimiter_code)
  string(ASCII 18 delimiter_start_escape_code)
  string(ASCII 19 delimiter_end_escape_code)
  string(ASCII 20 shorthand_indicator_escape_code)


  string(REPLACE "${shorthand_indicator_escape}" "${shorthand_indicator_escape_code}" input "${input}")
  string(REPLACE "${delimiter_start_escape}" "${delimiter_start_escape_code}" input "${input}")
  string(REPLACE "${delimiter_end_escape}" "${delimiter_end_escape_code}" input "${input}")


   string_encode_semicolon("${input}")
   ans(input)
   string_encode_bracket("${input}")
   ans(input)
  string(REPLACE "${delimiter_start}" "${delimiter_code}" input "${input}")
  string(REPLACE "${delimiter_end}" "${delimiter_code}" input "${input}")
  string(REPLACE "${shorthand_indicator}" "${shorthand_indicator_code}" input "${input}")

  ## match all fragments (literal and code fragments)
  set(code_fragment_regex "${delimiter_code}([^${delimiter_code}]*)${delimiter_code}")
  set(literal_fragment_regex "([^${delimiter_code}]+)")
  set(regex_cmake_function "[a-zA-Z_0-9]+\\([^\n${shorthand_indicator_code}]*\\)")



  string(REGEX REPLACE 
    "${shorthand_indicator_code}(${regex_cmake_function})"
    "${delimiter_code}=\\1${delimiter_code}"
    input
    "${input}"
  )
  string(REGEX REPLACE 
    "${shorthand_indicator_code}([^ ${shorthand_indicator_code}${delimiter_code}\r\n]+)"
    "${delimiter_code}=\"{\\1}\"${delimiter_code}"
    input
    "${input}"
  )



  string(REGEX MATCHALL "(${code_fragment_regex})|(${literal_fragment_regex})" fragments "${input}")

  ## decode escaped delimiters
  string(REPLACE "${delimiter_start_escape_code}" "${delimiter_start}"  fragments "${fragments}")
  string(REPLACE "${delimiter_end_escape_code}" "${delimiter_end}"  fragments "${fragments}")
  string(REPLACE "${shorthand_indicator_escape_code}" "${shorthand_indicator}"  fragments "${fragments}")
  string(REPLACE "${shorthand_indicator_code}" "${shorthand_indicator}" fragments "${fragments}")
  
  
  address_new()
  ans(result)
  address_append_string("${result}" "template_begin()")

  #set(result)
  foreach(fragment ${fragments})
    #message("${fragment}")
    # decode brackets and semicolon in fragment
    # now the fragment input is exactly the same as it was in input
    string_decode_bracket("${fragment}")
    ans(fragment)

    string_decode_semicolon("${fragment}")
    ans(fragment)

    if("${fragment}" MATCHES "${code_fragment_regex}")
      ## handle code fragment
      set(code "${CMAKE_MATCH_1}")

      ## special case <%>
      if("${code}" MATCHES "^>([a-zA-Z_0-9]+ )(.*)")
        set(output_var "${CMAKE_MATCH_1}")
        cmake_string_escape("${CMAKE_MATCH_2}")
        ans(output)
        set(code "set(${output_var} \"${output}\")\n")
      endif()

      ## special case <%= 
      if("${code}" MATCHES "^=(.*)")  
        set(code "${CMAKE_MATCH_1}")
        if("${code}" MATCHES "${regex_cmake_function}")
          set(code "set(__ans) \n ${code} \n template_out(\"\${__ans}\")")
        else()
          set(code "template_out_format(${code})")
        endif()
      else()

      endif()
      
      address_append_string("${result}" "\n${code}")

    else()
      ## handle literal fragment
      cmake_string_escape("${fragment}")
      ans(fragment)
      address_append_string("${result}" "\ntemplate_out(\"${fragment}\")")
    endif()
  endforeach()

  address_append_string("${result}" "\n template_end()")


  address_get(${result})
  ans(res)
  return_ref(res)
endfunction()





##
## `(<file path>)-> <cmake code>`
## 
## reads the contents of the specified path and generates a template from it
## * return
##   * the generated template code
##
function(template_compile_file path)
  fread("${path}")
  ans(content)
  template_compile("${content}")
  return_ans()
endfunction()




## `(<template file:<file path>> <?output file:<file path>>)-><file path>`
##
## compiles the specified template file to the speciefied output file
## if no output file is given the template file is expected to end with `.in`) and the 
## output file will be set to the same path without the `.in` ending
##
## Uses  see [`template_run_file`](#template_run_file) internally. 
##
## returns the path to which it was compiled
##
function(template_execute template_path)
  set(args ${ARGN})
  list_pop_front(args)
  ans(output_file)
  if(NOT output_file)
    if(NOT "${template_path}" MATCHES "\\.in$")
      message(FATAL_ERROR "expected a '.in' file")
    endif()
    string(REGEX REPLACE "(.+)\\.in" "\\1" output_file "${template_path}" )
  endif()

  template_run_file("${template_path}")
  ans(generated_content)
  fwrite("${output_file}" "${generated_content}")

  return("${output_file}")
endfunction()





## `(<template:<string>>)-><generated content:<string>>`
##
##  this function takes the input string compiles it and evaluates it
##  returning the result of the evaluations
##
function(template_run template)
  template_compile("${template}")
  ans(template_code)
  eval("${template_code}")
  return_ans()
endfunction()





##
## `(<template_path:<file path>>)-><generated content:string>`
##  
## opens the specified template and runs it in its directory
## keeps track of recursive template calling
## * returns 
##    * the output of the template
## * scope
##    * `pwd()` is set to the templates path
##    * `${template_path}` is set to the path of the current template
##    * `${template_dir}` is set to the directory of the current template
##    * `${root_template_dir}` is set to the directory of the first template run
##    * `${root_template_path}` is set to the path of the first template run
##    * `${parent_template_dir}` is set to the calling templates dir 
##    * `${parent_template_path}`  is set to the calling templates path
## 
## 
function(template_run_file template_path)
  template_compile_file("${template_path}")
  ans(template)

  get_filename_component(template_dir "${template_path}" PATH)

  if(NOT root_template_path)
    set(root_template_path "${template_path}")
    get_filename_component(root_template_dir "${template_path}" PATH)
    set(parent_template_dir)
    set(parent_template_path)
  endif()
  set(parent_template_path "${template_path}")
  set(parent_template_dir "${template_dir}")
  path_relative("${root_template_path}" "${template_path}")
  ans(relative_template_path)

  path_relative("${root_template_dir}" "${template_dir}")
  ans(relative_template_dir)

  pushd("${template_dir}")
    eval("${template}")
    ans(result)
  popd()
  return_ref(result)
endfunction()




# checks to see if an assertion holds true. per default this halts the program if the assertion fails
# usage:
# assert(<assertion> [MESSAGE <string>] [MESSAGE_TYPE <FATAL_ERROR|STATUS|...>] [RESULT <ref>])
# <assertion> := <truth-expression>|[<STRING|NUMBER>EQUALS <list> <list>]
# <truth-expression> := anything that can be checked in if(<truth-expression>)
# <list> := <ref>|<value>|<value>;<value>;...
# if RESULT is set then the assertion will not cause the program to fail but return the true or false
# if ACCU is set result is treated as a list and if an assertion fails the failure message is added to the end of result
# examples
# 
# assert("3" STREQUAL "3") => nothing happens
# assert("3" STREQUAL "b") => FATAL_ERROR assertion failed: '"3" STREQUAL "b"'
# assert(EXISTS "none/existent/path") => FATAL_ERROR assertion failed 'EXISTS "none/existent/path"' 
# assert(EQUALS a b) => FATAL_ERROR assertion failed ''
# assert(<assertion> MESSAGE "hello") => if assertion fails prints "hello"
# assert(<assertion> RESULT res) => sets result to false if assertion fails or to true if it holds
# assert(EQUALS "1;3;4;6;7" "1;3;4;6;7") => nothing happens lists are equal
# assert(EQUALS 1 2 3 4 1 2 3 4) =>nothing happes lists are equal (see list_equal)
# assert(EQUALS C<list> <list> COMPARATOR <comparator> )... todo
# todo: using the variable result as a boolean check fails because
# the name is used inside assert

function(assert)
	# parse arguments
	set(options == EQUALS AREEQUAL ARE_EQUAL ACCU SILENT DEREF INCONCLUSIVE ISNULL ISNOTNULL)
	set(oneValueArgs EXISTS  COUNT MESSAGE RESULT MESSAGE_TYPE CONTAINS MISSING MATCH MAP_MATCHES FILE_CONTAINS)
	set(multiValueArgs CALL PREDICATE )
	set(prefix)
	cmake_parse_arguments("${prefix}" "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
	#_UNPARSED_ARGUMENTS
	set(result)
 

	#if no message type is set set FATAL_ERROR
	# so execution halts on failing assertion
	if(NOT _MESSAGE_TYPE)
		set(_MESSAGE_TYPE FATAL_ERROR)
	endif()




	# if continue is set: set the mesype to statussage t
	if(_RESULT AND _MESSAGE_TYPE STREQUAL FATAL_ERROR)
		set(_MESSAGE_TYPE STATUS)
	endif()

	if(_DEREF)
		#map_format( "${_UNPARSED_ARGUMENTS}")
		format("${_UNPARSED_ARGUMENTS}")
		ans(_UNPARSED_ARGUMENTS)
	endif()

	## transform call into further arguments
	if(_CALL)
		call(${_CALL})

		ans(vars)
		list(APPEND _UNPARSED_ARGUMENTS ${vars})
	endif()

	# 
	if(_EQUALS OR _ARE_EQUAL OR _AREEQUAL)
		if(NOT _MESSAGE)
		set(_MESSAGE "assertion failed: lists not equal [${_UNPARSED_ARGUMENTS}]")
		endif()
		list_equal(${_UNPARSED_ARGUMENTS})
		ans(result)
	elseif(_EXISTS)
		list_pop_front(_UNPARSED_ARGUMENTS)
		ans(not)
		if(NOT "${not}_" STREQUAL "NOT_")
			set(not)
		endif()
		path("${_EXISTS}")
		ans(_EXISTS)
		if(NOT _MESSAGE)
			set(_MESSAGE "assertion failed: file does not exists ${_EXISTS}")
		endif()

		if(${not} EXISTS "${_EXISTS}")
			set(result true)
		else()
			set(result false)
		endif()
	elseif(_PREDICATE)
		if(NOT _MESSAGE)
			set(_MESSAGE "assertion failed: predicate does not hold: '${_PREDICATE}'")
		endif()
	#	message("predicate '${_PREDICATE}'")
		call(${_PREDICATE}(${_UNPARSED_ARGUMENTS}))
		ans(result)
	elseif(_FILE_CONTAINS)
		if(NOT _MESSAGE)
			set(_MESSAGE "assertion failed: file '${_FILE_CONTAINS}' does not contain: ${_UNPARSED_ARGUMENTS}")
		endif()
		file(READ "${_FILE_CONTAINS}" contents)
		if("${contents}" MATCHES "${_UNPARSED_ARGUMENTS}")
			set(result true)
		else()
			set(result false)
		endif()
	elseif(_INCONCLUSIVE)
		if(NOT _MESSAGE)
			set(_MESSAGE "assertion inconclusive")
		endif()
		set(result true)

	elseif(_MATCH)
		if(NOT _MESSAGE)
			set(_MESSAGE "assertion failed: input does not match '${_MATCH}'")
		endif()
		list_extract_flag_name(_UNPARSED_ARGUMENTS NOT)
		ans(not)

		if(${not} "${_UNPARSED_ARGUMENTS}" MATCHES "${_MATCH}")
			set(result true)
		else()
			set(result false)
		endif()
	elseif(_COUNT OR "_${_COUNT}" STREQUAL _0)
			list(LENGTH _UNPARSED_ARGUMENTS len)
		if(NOT _MESSAGE)
			set(_MESSAGE "assertion failed: expected '${_COUNT}' elements got '${len}'")
		endif()
		eval_truth( "${len}" EQUAL "${_COUNT}")
		ans(result)
	elseif(_ISNULL)
		if("${_UNPARSED_ARGUMENTS}_" STREQUAL "_")
			set(result true)
		else()
			set(_MESSAGE "assertion failed: '${_UNPARSED_ARGUMENTS}' is not null")
			set(result false)
		endif()
	elseif(_ISNOTNULL)
		if("${_UNPARSED_ARGUMENTS}_" STREQUAL "_")
			set(result false)
		else()
			set(_MESSAGE "assertion failed: argument is null")
			set(result true)
		endif()
	elseif(_MAP_MATCHES)
		data("${_MAP_MATCHES}")
		ans(_MAP_MATCHES)
		map_match("${_UNPARSED_ARGUMENTS}" "${_MAP_MATCHES}")
		ans(result)
		if(NOT _MESSAGE)
			json("${_MAP_MATCHES}")
			ans(expected)
			json("${_UNPARSED_ARGUMENTS}")
			ans(actual)
			set(_MESSAGE "assertion failed: match failed: expected: '${expected}' actual:'${actual}'")
		endif()

	elseif(_CONTAINS OR _MISSING)
		if(NOT _MESSAGE)
		set(_MESSAGE "assertion failed: list does not contain '${_CONTAINS}' list:(${_UNPARSED_ARGUMENTS})")
		endif()
		list(FIND _UNPARSED_ARGUMENTS "${_CONTAINS}" idx)
		
		if(${idx} LESS 0)
			if(_MISSING)
				set(result true)
			else()
				set(result false)
			endif()
		else()
			if(_MISSING)
				set(result false)
			else()
				set(result true)
			endif()
		endif()

	else()
		# if nothing else is specified use _UNPARSED_ARGUMENTS as a truth expresion
		eval_truth( (${_UNPARSED_ARGUMENTS}))
		ans(result)
	endif()

	# if message is not set add default message
	if("${_MESSAGE}_" STREQUAL "_")
		list_to_string( _UNPARSED_ARGUMENTS " ")
		ans(msg)
		set(_MESSAGE "assertion failed1: '${_UNPARSED_ARGUMENTS}'")
	endif()

	# print message if assertion failed, SILENT is not specified or message type is FATAL_ERROR
	if(NOT result)
		if(_MESSAGE_TYPE STREQUAL "FATAL_ERROR")
			message("'${_MESSAGE}'")
			message(PUSH "log:")
			log_print(10)
			message(POP)
			message(FATAL_ERROR " ")
		endif()

		if(NOT _SILENT OR _MESSAGE_TYPE STREQUAL "FATAL_ERROR")
			message(${_MESSAGE_TYPE} "'${_MESSAGE}'")
		endif()
	endif()

	# depending on wether to accumulate the results or not 
	# set result to a boolean or append to result list
	if(_ACCU)
		set(lst ${_RESULT})
		list(APPEND lst ${_MESSAGE})
		set(${_RESULT} ${lst} PARENT_SCOPE)
	else()
		set(${_RESULT} ${result} PARENT_SCOPE)
	endif()

endfunction()






function(assertf)
  set(args ${ARGN})
  list_extract_flag(args DEREF)
  assert(${args} DEREF)
  return()
endfunction()




## fails if ARGN does not match expected value
## see map_match
function(assert_matches expected)
  assign(expected = ${expected})
  assign(actual = ${ARGN})
  map_match("${actual}" "${expected}")
  ans(result)
  if(NOT result)
    echo_append("expected: ")
    json_print(${expected})
    echo_append("actual:")
    json_print(${actual})
    _message(FATAL_ERROR "values did not match")
  endif()
endfunction()





  function(define_test_function name parse_function_name)
    set(args ${ARGN})
    list(LENGTH args arg_len)
    matH(EXPR arg_len "${arg_len} + 1")


    string_combine(" " ${args})
    ans(argstring)
    set(evaluated_arg_string)
    foreach(arg ${ARGN})
      set(evaluated_arg_string "${evaluated_arg_string} \"\${${arg}}\"")
    endforeach()
   # messagE("argstring ${argstring}")
   # message("evaluated_arg_string ${evaluated_arg_string}")
    eval("
      function(${name} expected ${argstring})
        arguments_encoded_list2(${arg_len} \${ARGC})
        ans(encoded_arguments)
        arguments_sequence(${arg_len} \${ARGC})
        ans(arguments_sequence)
        set(args \${ARGN})
        list_extract_flag(args --print)
        ans(print)
        data(\"\${expected}\")
        ans(expected)
        #if(parsed)
        #  set(expected \${parsed})
        #endif()
        #if(NOT expected)
        #  message(FATAL_ERROR \"invalid expected value\")
        #endif()
        ${parse_function_name}(${evaluated_arg_string} \${args})
        ans(uut)

        if(print)
          json_print(\${uut})
        endif()


        
        map_match(\"\${uut}\" \"\${expected}\")
        ans(res)
        if(NOT res)
          echo_append(\"actual: \")
          json_print(\${uut})
          echo_append(\"expected: \")
          json_print(\${expected})
        endif()
        assert(res MESSAGE \"values do not match\")
      endfunction()

    ")
    return()
  endfunction()





function(test_execute test)
  event_addhandler(on_log_message "[](msg) message(FORMAT '{msg.message}') ")
  ans(handler)

  message(STATUS "running test ${test}...")

  #initialize variables which test can use

#  set(test_name "${test}")
  get_filename_component(test_name "${test}" NAME_WE) 

  # intialize message listener

  # setup a directory for the test
  string_normalize("${test_name}")
  ans(test_dir)
  cmakepp_config(temp_dir)
  ans(temp_dir)
  set(test_dir "${temp_dir}/tests/${test_dir}")
  file(REMOVE_RECURSE "${test_dir}")
  get_filename_component(test_dir "${test_dir}" REALPATH)
  path_qualify(test)
  message(STATUS "test directory is ${test_dir}")  
  pushd("${test_dir}" --create)
  timer_start("test duration")
  call("${test}"())
  
  set(time)
  timer_elapsed("test duration")
  ans(time)
  popd()

  event_removehandler(on_log_message ${handler})


  message(STATUS "done after ${time} ms")
endfunction()





function(test_execute_glob)
  timer_start(test_run)
  cd("${CMAKE_CURRENT_BINARY_DIR}")
  glob(${ARGN})
  ans(test_files)
  list(LENGTH test_files len)
  ## sort the test files so that they are always executed in the same order
  list(SORT test_files)
  message("found ${len} tests in path for '${ARGN}'")
  set(i 0)
  foreach(test ${test_files})
    math(EXPR i "${i} + 1")
    message(STATUS "test ${i} of ${len}")
    message_indent_push()
    test_execute("${test}")
    message_indent_pop()
    message(STATUS "done")
  endforeach()

  timer_print_elapsed(test_run)


endfunction()




##
##
## runs all tests specified in glob expressions in parallel 
function(test_execute_glob_parallel)
  list_extract_flag(args --no-status)
  ans(no_status)
  set(args ${ARGN})

  ## get all test files 
  cd("${CMAKE_CURRENT_BINARY_DIR}")
  glob("${args}")
  ans(test_files)


  ## setup refs which are used by callback
  list(LENGTH test_files test_count)
  address_set(test_count ${test_count})
  address_set(tests_failed)
  address_set(tests_succeeded)
  address_set(tests_completed)

  ## 
  set(processes)

  ## status callback  shows a status message with current progress and a spinner
  set(status_callback)
  if(NOT no_status)
    function_new()
    ans(status_callback)  
    function(${status_callback})
      address_get(tests_failed)
      ans(tests_failed)
      address_get(tests_succeeded)
      ans(tests_succeeded)
      address_get(test_count)
      ans(test_count)
      address_get(tests_completed)
      ans(tests_completed)

      list(LENGTH tests_failed failure_count)
      list(LENGTH tests_succeeded success_count)
      list(LENGTH tests_completed completed_count)

      timer_elapsed(test_time_sum)
      ans(elapsed_time)
      spinner()
      ans(spinner)
      status_line("${completed_count}  / ${test_count}  ok: ${success_count} nok: ${failure_count}  (running ${running_count}) (elapsed time ${elapsed_time} ms) ${spinner}")
    endfunction()
    ## add flag
    set(status_callback --idle-callback ${status_callback})
  endif()

  ## test complete callback outputs info and if test fails also the stderr of the test's process
  function_new()
  ans(test_complete_callback)
  function(${test_complete_callback} process_handle)
    map_tryget(${process_handle} exit_code)
    ans(error)

    if(error)
      address_append(tests_failed ${process_handle})
      message(FORMAT "failed: {process_handle.test_file}")
      message(FORMAT "test output: {process_handle.stderr}")
    else()
      address_append(tests_succeeded ${process_handle})
      message(STATUS FORMAT "success: {process_handle.test_file}")

    endif()
    address_append(tests_completed ${process_handle})
  endfunction()

  ## init time for all tests
  timer_start(test_time_sum)

  ## start every test in parallel 
  foreach(test_file ${test_files})
    ## start test in a async process and add it to the process list
    cmakepp("test_execute" "${test_file}" --async)  # wrapped execute()
    ans(process)
    list(APPEND processes ${process})    

    ## add a property to process handle which is passed on to callback
    map_set(${process} test_file ${test_file})

    ## add a listener to on_terminated event from process handle
    assign(success = process.on_terminated.add(${test_complete_callback}))

    ## since starting a process is relatively slow I added a process wait -1 
    ## here that gathers all completed processes 
    ## -1 indicates that it will take only the finished processes
    process_wait_n(-1 ${processes} ${status_callback})
    ans(complete)
    ## remove the completed tests from the processes so that they will not be waited for again
    if(complete)
      list(REMOVE_ITEM processes ${complete})
    endif()
  endforeach()


      
  ## wait for all remaining processes (* indicates that all processes are to be waited for)
  process_wait_n(* ${processes} ${status_callback})

  # print status once
  address_get(tests_failed)
  ans(tests_failed)
  address_get(tests_succeeded)
  ans(tests_succeeded)
  address_get(test_count)
  ans(test_count)
  address_get(tests_completed)
  ans(tests_completed)

  list(LENGTH tests_failed failure_count)
  list(LENGTH tests_succeeded success_count)
  list(LENGTH tests_completed completed_count)

  timer_elapsed(test_time_sum)
  ans(elapsed_time)


   status_line("")
   message("\n\n${completed_count}  / ${test_count}  ok: ${success_count} nok: ${failure_count} (elapsed time ${elapsed_time} ms)")

   foreach(failure ${tests_failed})
    map_tryget(${failure} test_file)
    ans(test_file)
    message(FORMAT "FAILED: ${test_file} ({failure.exit_code})")
    message(FORMAT "output:\n{failure.stderr}")
   endforeach()

if(failure_count)
  messagE(FATAL_ERROR "failed to execute all tests successfully")
endif()
endfunction()





function(test_create file)

  get_filename_component(test_name "${test}" NAME_WE) 
  # setup a directory for the test
  string_normalize("${test_name}")
  ans(test_dir)
  cmakepp_config(temp_dir)
  ans(temp_dir)
  set(test_dir "${temp_dir}/tests/${test_dir}")
  file(REMOVE_RECURSE "${test_dir}")
  get_filename_component(test_dir "${test_dir}" REALPATH)
  
  map_capture_new(test_dir test_name)
  return_ans()  
endfunction()






## returns the list of known timers
function(timers_get)
  map_keys(__timers)
  ans(timers)
  return_ref(timers)
endfunction()





## prints the elapsed time for all known timer
function(timers_print_all)
  timers_get()
  ans(timers)
  foreach(timer ${timers})
    timer_print_elapsed("${timer}")
  endforeach()  
  return()
endfunction()




## removes the specified timer
function(timer_delete id)
  map_remove(__timers "${id}")
  return()
endfunction()





# returns the time elapsed since timer identified by id was started
function(timer_elapsed id)      
  millis()
  ans(now)
  map_get(__timers ${id})
  ans(then)
  # so this has to be done because cmake can't handle numbers which are too large
  string_trim_to_difference(then now)
  map_tryget(__timers __prejudice)      
  ans(prejudice)
  ## if now and the are equal null is returned so here it normalized
  if(NOT now)
    set(now 0)
  endif()
  if(NOT then)
    set(then 0)
  endif()
  math(EXPR elapsed "${now} - ${then} - ${prejudice}")
  math_max(${elapsed} 0)
  ans(elapsed)
  return("${elapsed}")
endfunction()




## prints elapsed time for timer identified by id
function(timer_print_elapsed id)
  timer_elapsed("${id}")
  ans(elapsed)
  message("${ARGN}${id}: ${elapsed} ms")
  return()
endfunction()





## starts a timer identified by id
## 
function(timer_start id)
  map_set_hidden(__timers __prejudice 0)

  # actual implementation of timer_start
  function(timer_start id)
    return_reset()      
    millis()
    ans(millis)
    map_set(__timers ${id} ${millis})
  endfunction()



  ## this is run the first time a timer is started: 
  ## it calculates a prejudice value 
  ## (the time it takes from timer_start to timer_elapsed to run)
  ## this prejudice value is then subtracted everytime elapse is run
  ## thus minimizing the error

  #foreach(i RANGE 0 3)
    timer_start(initial)  
    timer_elapsed(initial)
    ans(prejudice)

    map_tryget(__timers __prejudice)
    ans(pre)
    math(EXPR prejudice "${prejudice} + ${pre}")
    map_set_hidden(__timers __prejudice ${prejudice})
  #endforeach()


  timer_delete(initial)


  return_reset()
  timer_start("${id}")
endfunction()




# compiles a tool (single cpp file with main method)
# and create a cmake function (if the tool is not yet compiled)
# expects tool to print cmake code to stdout. this code will 
# be evaluated and the result is returned  by the tool function
# the tool function's name is name
# currently only allows default headers
function(compile_tool name src)
  checksum_string("${src}")
  ans(chksum)

  cmakepp_config(temp_dir)
  ans(temp_dir)


  set(dir "${temp_dir}/tools/${chksum}")

  if(NOT EXISTS "${dir}")

    pushd("${dir}" --create)
    fwrite("main.cpp" "${src}")
    fwrite("CMakeLists.txt" "
      project(${name})
      if(\"\${CMAKE_CXX_COMPILER_ID}\" STREQUAL \"GNU\")
        include(CheckCXXCompilerFlag)
        CHECK_CXX_COMPILER_FLAG(\"-std=c++11\" COMPILER_SUPPORTS_CXX11)
        CHECK_CXX_COMPILER_FLAG(\"-std=c++0x\" COMPILER_SUPPORTS_CXX0X)
        if(COMPILER_SUPPORTS_CXX11)
          set(CMAKE_CXX_FLAGS \"\${CMAKE_CXX_FLAGS} -std=c++11\")
        elseif(COMPILER_SUPPORTS_CXX0X)
          set(CMAKE_CXX_FLAGS \"\${CMAKE_CXX_FLAGS} -std=c++0x\")
        else()
                message(STATUS \"The compiler \${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.\")
        endif()

      endif()
      set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG   \${CMAKE_BINARY_DIR}/bin)
      set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE \${CMAKE_BINARY_DIR}/bin)
      set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG   \${CMAKE_BINARY_DIR}/lib)
      set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE \${CMAKE_BINARY_DIR}/lib)
      set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG   \${CMAKE_BINARY_DIR}/lib)
      set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE \${CMAKE_BINARY_DIR}/lib)
      set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/lib)
      set(CMAKE_LIBRARY_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/lib)
      set(CMAKE_RUNTIME_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/bin)
      add_executable(${name} main.cpp)
      ")
    mkdir(build)
    cd(build)
    cmake(../ --process-handle)
    ans(configure_result)
    cmake(--build . --process-handle)
    ans(build_result)


    map_tryget(${build_result} exit_code)
    ans(error)
    map_tryget(${build_result} stdout)
    ans(log)
    popd()

    if(NOT "${error}" STREQUAL "0")        
      message(FATAL_ERROR "failed to compile tool :\n ${log}")
      rm("${dir}")
    endif()


  endif()
  
        
  wrap_executable_bare("__${name}" "${dir}/build/bin/${name}")

  eval("
    function(${name})

      __${name}(\${ARGN})
      ans_extract(error)
      if(error)
        message(FATAL_ERROR \"${name} tool (${dir}/build/bin/${name}) failed with \${error}\")
      endif()
      ans(stdout)
      eval(\"\${stdout}\")
     # _message(\${__ans})
      return_ans()
    endfunction()
    ")



endfunction()




## prompts the user for input on the console
function(prompt type)

  
  query_type(prompt_input "${type}")
  return_ans()
endfunction()






  function(prompt_input)
    echo_append("> ")
    read_line()
    ans(res)
    return_ref(res)
  endfunction()







  function(prompt_property prop)
    query_property(prompt_input "${prop}")
    return_ans()
  endfunction()





    ## parses a property 
  function(property_def prop)
    data("${prop}")
    ans(prop)
    is_map("${prop}")
    ans(ismap)

    if(ismap)
      return_ref(prop)
    endif()

    map_new()
    ans(res)


    string_take_regex(prop "[^:]+")
    ans(prop_name)

    if("${prop}_" STREQUAL "_")
      set(prop_type "any")
    else()
      string_take(prop :)
      set(prop_type "${prop}")
    endif()


    map_set(${res} property_name "${prop_name}")
    map_set(${res} display_name "${prop_name}")
    map_set(${res} property_type "${prop_type}")
    return_ref(res)
  endfunction()





  function(query_fundamental input_callback type)
      
      call("${input_callback}"(${type}))
      ans(res)
      return_ref(res)
  endfunction()





  function(query_properties input_callback type)

    map_new()
    ans(res)

    message_indent_push()
    foreach(property ${properties})
      property_def("${property}")
      ans(property)
      query_property("${input_callback}" "${property}")
      ans(value)
      map_tryget(${property} property_name)
      ans(prop_name)
      map_set(${res} "${prop_name}" "${value}")
    endforeach()
    message_indent_pop()
    return_ref(res)
  endfunction()







  ## queries a property
  function(query_property input_callback property)
    property_def("${property}")
    ans(property)
    map_tryget(${property} "display_name")
    ans(display_name)
    map_tryget(${property} "property_type")
    ans(property_type)
    type_def("${property_type}")
    ans(property_type)
    map_tryget(${property_type} type_name)
    ans(property_type_name)
    message("enter ${display_name} (${property_type_name})")
    query_type("${input_callback}" "${property_type}")
    ans(res)
    return_ref(res)
  endfunction()

  









  ## queries a type
  function(query_type input_callback type)
    type_def("${type}")
    ans(type)

    map_tryget(${type} properties)
    ans(properties)

    list(LENGTH properties is_complex)

    if(NOT is_complex)
      query_fundamental("${input_callback}" "${type}")
      ans(res)
    else()
      query_properties("${input_callback}" "${type}")
      ans(res)      
    endif()
    return_ref(res)
  endfunction()  





## parses and registers a type or returns an existing one by type_name

function(type_def)
  function(type_def)
    data("${ARGN}")
    ans(type)

    if("${type}_" STREQUAL "_")
      set(type any)
    endif()


    list(LENGTH type length)
    if(length GREATER 1)
      map_new()
      ans(t)
      map_set(${t} properties ${type})
      set(type ${t})
    endif()


    is_map("${type}")
    ans(ismap)
    if(ismap)
      map_tryget(${type} type_name)
      ans(type_name)
      if("${type_name}_" STREQUAL "_")
        string(RANDOM type_name)
        map_set("${type}" "anonymous" true)
        #map_set(${type} "type_name" "${type_name}")
      else()
        map_set("${type}" "anonymous" false)
      endif()
    
      map_tryget(data_type_map "${type_name}")
      ans(registered_type)
      if(NOT registered_type)
        map_set(data_type_map "${type_name}" "${type}")
      endif()
      
      map_tryget("${type}" properties)
      ans(props)
      is_map("${props}")
      ans(ismap)
      if(ismap)
        map_iterator("${props}")
        ans(it)
        set(props)
        while(true)
          map_iterator_break(it)
          list(APPEND props "${it.key}:${it.value}")

        endwhile()
        map_set(${type} properties "${props}")
      endif()

      return_ref(type)



    endif()


    map_tryget(data_type_map "${type}")
    ans(res)
    if(res)
      return_ref(res)
    endif()


    map_new()
    ans(res)

    map_set(${res} type_name "${type}")
    map_set(data_type_map "${type}" "${res}")
    return_ref(res)
  endfunction()

  type_def("{
    type_name:'string'
    }")


  type_def("{
    type_name:'int',
    regex:'[0-9]+'
  }")

  type_def("{
    type_name:'any'
  }")


  type_def("{
    type_name:'bool',
    regex:'true|false'
  }")

  
  type_def(${ARGN})
  return_ans()
endfunction()







  macro(arguments_extract_typed_values __start_arg_index __end_arg_index)
    set(__arg_res)   
    if(${__end_arg_index} GREATER ${__start_arg_index})

      math(EXPR __last_arg_index "${__end_arg_index} - 1")
      foreach(i RANGE ${__start_arg_index} ${__last_arg_index} )        
        encoded_list("${ARGV${i}}")
        list(APPEND __arg_res "${__ans}")
        #message("argv: '${ARGV${i}}' -> '${__ans}'")
      endforeach()
    endif()
    list_extract_typed_values(__arg_res ${ARGN})
  endmacro()






  function(list_extract_typed_value __lst __letsv_def)
    regex_cmake()
   # message("${${__lst}}")
    set(__letsv_regex "^([<\\[])(${regex_cmake_flag})(:(.*))?(\\]|>)$")
    if("${__letsv_def}" MATCHES "${__letsv_regex}")
      set(__letsv_name ${CMAKE_MATCH_2})
      set(__letsv_type ${CMAKE_MATCH_3})
      if("${CMAKE_MATCH_1}" STREQUAL "<")
        set(__letsv_positional true)
      else()
        set(__letsv_positional false)
      endif()

      string(REGEX REPLACE "--(.*)" "\\1" __letsv_identifier "${__letsv_name}")
      string(REPLACE "-" "_" __letsv_identifier "${__letsv_identifier}")

      if(NOT __letsv_type)

      elseif("${__letsv_type}" MATCHES "<(${regex_cmake_identifier})(.*)>(.*)")
        #_message("${__letsv_type} : 0 ${CMAKE_MATCH_0} 1  ${CMAKE_MATCH_1} 2 ${CMAKE_MATCH_2} 3 ${CMAKE_MATCH_3}")
        set(__letsv_type "${CMAKE_MATCH_1}")
        set(__letsv_optional false)
        set(__letsv_default_value)
        if("${CMAKE_MATCH_3}_" STREQUAL "?_")
          set(__letsv_optional true)
        elseif("${CMAKE_MATCH_3}" MATCHES "^=(.*)")
          set(__letsv_default_value ${CMAKE_MATCH_1})
        endif()


        #print_vars(__letsv_identifier __letsv_optional)
      else() 
        message(FATAL_ERROR "invalid __letsv_type __letsv_def: '${__letsv_type}' (needs to be inside angular brackets)")
      endif()


      if(NOT __letsv_positional AND NOT __letsv_type)
        list_extract_flag(${__lst} ${__letsv_name})
        ans(__letsv_value)
      elseif(NOT __letsv_positional)
        list_extract_labelled_value(${__lst} ${__letsv_name})
        ans(__letsv_value)
      else()
        list_pop_front(${__lst})
        ans(__letsv_value)
      endif()

      encoded_list_decode("${__letsv_value}")
      ans(__letsv_value)

      if("${__letsv_value}_" STREQUAL "_")
        set(__letsv_value ${__letsv_default_value})
      endif()

      if(NOT __letsv_optional AND NOT "${__letsv_value}_" STREQUAL "_" )
        if(__letsv_type AND NOT "${__letsv_type}" MATCHES "^(any)|(string)$" AND COMMAND "t_${__letsv_type}")  
          eval("t_${__letsv_type}(\"${__letsv_value}\")")
          ans_extract(__letsv_success)
          ans(__letsv_value_parsed)

          if(NOT __letsv_success)
            message(FATAL_ERROR "could not parse ${__letsv_type} from ${__letsv_value}")
          endif()
          set(__letsv_value ${__letsv_value_parsed})

        endif()
      else()
        ## optional
      endif()
        


      set(__ans ${__letsv_identifier} ${__letsv_value} PARENT_SCOPE)
      set(${__lst} ${${__lst}} PARENT_SCOPE)
    else()


      message(FATAL_ERROR "invalid definition: ${__letsv_def}")
    endif()



  endfunction()





  function(list_extract_typed_values __lst)
    regex_cmake()
    string(REGEX MATCHALL "(^|;)<.*>($|;)" __letv_positionals "${ARGN}")
    string(REGEX MATCHALL "(^|;)\\[.*\\]($|;)" __letv_nonpositionals "${ARGN}")
    set(names)    
    foreach(__letv_arg ${__letv_nonpositionals} ${__letv_positionals})
      list_extract_typed_value(${__lst} "${__letv_arg}")
      ans_extract(__letv_name)
      ans(__letv_value)
      #print_vars(__letv_name __letv_value ${__lst})
      set("${__letv_name}" ${__letv_value} PARENT_SCOPE)
      list(APPEND names ${__letv_name})
    endforeach()
    set(__extracted_names ${names} PARENT_SCOPE)

    return_ref(${__lst})
  endfunction()





  function(t_bool)
    if(ARGN)
      return(true true)
    else()
      return(true false)
    endif()    
  endfunction()





  function(t_callable)
    if(NOT ARGN)
      return(false)
    endif()
    callable("${ARGN}")
    ans(callable)
    return(true ${callable})
  endfunction()





function(t_int)
  if("${ARGN}" MATCHES "-?(0|([1-9][0-9]*))")
    return(true ${ARGN})
  else()
    return(false)
  endif()
endfunction()




function(t_map)
  obj("${ARGN}")
  ans(map)
  if(NOT map)
    return(false)
  endif()
  return(true ${map})
endfunction()






  function(dns_parse input)
    regex_uri()

    string_take_regex_replace(input "${dns_user_info_regex}" "\\1")
    ans(user_info)
    
    set(host_port "${input}")


    string_take_regex_replace(input "${dns_host_regex}" "\\1")
    ans(host)

    string_take_regex(input "${dns_port_regex}")
    ans(port)


    if(port AND NOT "${port}" LESS 65536)
      return()
    endif()
    set(rest ${input})

    set(input "${host}")
    string_take_regex(input "${ipv4_regex}")
    ans(ip)

    set(top_label)
    set(labels)
    if(NOT ip)
      while(true)
        string_take_regex(input "${dns_domain_label_regex}")
        ans(label)
        if("${label}_" STREQUAL "_")
          break()

        endif()
        set(top_label "${label}")
        list(APPEND labels "${label}")
        string_take_regex(input "${dns_domain_label_separator}")
        ans(separator)
        if(NOT separator)
          break()
        endif()

      endwhile()


    endif()

    list(LENGTH labels len)
    set(domain)
    if("${len}" GREATER 1)
      list_slice(labels -3 -1)
      ans(domain)
      string_combine("." ${domain} )
      ans(domain)
    else()
      set(domain "${top_label}")
    endif()

    string_split_at_first(user_name password "${user_info}" ":")


    set(normalized_host "${host}")
    if("${normalized_host}_" STREQUAL "_" )
      set(normalized_host localhost)
    endif()

    map_capture_new(
      user_info
      user_name
      password
      host_port
      host
      normalized_host
      labels
      top_label
      domain
      ip
      port
      rest
      )
    return_ans()
  endfunction()




function(uri uri)
  is_address("${uri}")
  ans(ismap)
  if(ismap)
    return_ref(uri)
  endif()
  uri_parse("${uri}" ${ARGN})
  ans(uri)
  return_ref(uri)
endfunction()






## 
## checks to see if all specified items are in list 
## using list_check_items
## 
function(uri_check_scheme uri)
  uri_coerce(uri)
  map_tryget(${uri} schemes)
  ans(schemes)
  list_check_items(schemes ${ARGN})
  return_ans()
endfunction()




##
## forces the specified variable reference to become an uri
macro(uri_coerce __uri_ref)
  uri("${${__uri_ref}}")
  ans("${__uri_ref}")
endmacro()




## decodes an uri encoded string ie replacing codes %XX with their ascii values
 function(uri_decode str)
  set(hex "[0-9A-Fa-f]")
  set(encoded "%(${hex}${hex})")
  string(REGEX MATCHALL "${encoded}" matches "${str}")

  list(REMOVE_DUPLICATES matches)
  foreach(match ${matches})
    string(SUBSTRING "${match}" 1 -1  hex_code)
    hex2dec("${hex_code}")
    ans(dec_code)
    string(ASCII "${dec_code}" char)
    string(REPLACE "${match}" "${char}" str "${str}")
  endforeach()
  return_ref(str)

 endfunction()




## encodes a string to uri format 
## if you can pass decimal character codes  which are encoded 
## if you do not pass any codes  the characters  recommended by rfc2396
## are encoded
function(uri_encode str ) 

  if(NOT ARGN)
    uri_recommended_to_escape()
    ans(codes)
    list(APPEND codes)
  else()
    set(codes ${ARGN})
  endif()

  foreach(code ${codes})
    string(ASCII "${code}" char)
    dec2hex("${code}")
    ans(hex)
    # pad with zero
    if("${code}" LESS  16)
      set(hex "0${hex}")
    endif()

    string(REPLACE "${char}" "%${hex}" str "${str}" )
  endforeach()

  return_ref(str)
endfunction()







  function(uri_format uri)
    set(args ${ARGN})

    list_extract_flag(args --no-query)
    ans(no_query)

    list_extract_flag(args --no-scheme)
    ans(no_scheme)

    list_extract_labelled_value(args --remove-scheme)
    ans(remove_scheme)



    obj("${args}")
    ans(payload)


    uri("${uri}")
    ans(uri)
    map_tryget("${uri}" params)
    ans(params)

    if(payload)

      map_merge( "${params}" "${payload}")
      ans(params)
    endif()

    set(query)
    if(NOT no_query)
      uri_params_serialize("${params}")
      ans(query)
      if(query)
        set(query "?${query}")
      endif()
    endif()

    if(NOT no_scheme)

      if(NOT remove_scheme STREQUAL "")
        map_tryget("${uri}" schemes)
        ans(schemes)

        string(REPLACE "+" ";" remove_scheme "${remove_scheme}")

        list_remove(schemes ${remove_scheme})
        string_combine("+" ${schemes})
        ans(scheme)
      else()
        map_tryget("${uri}" scheme)
        ans(scheme)
      endif()

      if(NOT "${scheme}_" STREQUAL "_")
        set(scheme "${scheme}:")
      endif()
    endif()

    map_tryget("${uri}" net_path)
    ans(net_path)

    if("${net_path}_" STREQUAL "_")
      map_tryget(${uri} path)
      ans(path)
      set(uri_string "${scheme}${path}${query}")
    else()
      set(uri_string "${scheme}//${net_path}${query}")
    endif()
    return_ref(uri_string)

  endfunction()





## normalizes the input for the uri
## expects <uri> to have a property called input
## ensures a property called uri is added to <uri> which contains a valid uri string 
function(uri_normalize_input input_uri)
  set(flags ${ARGN})


  # options  
  set(handle_windows_paths true)
  set(default_file_scheme true)
  set(driveletter_separator :)
  set(delimiters "''" "\"\"" "<>")
  set(encode_input 32) # character codes to encode in delimited input
  set(ignore_leading_whitespace true)
  map_get("${input_uri}" input)
  ans(input)

  if(ignore_leading_whitespace)
    string_take_whitespace(input)
  endif()

  set(delimited)
  foreach(delimiter ${delimiters})
    string_take_delimited(input "${delimiter}")
    ans(delimited)
    if(NOT "${delimited}_" STREQUAL "_")
      break()
    endif()
  endforeach()

  set(delimiters "${delimiter}")

    # if string is delimited encode whitespace 
    if(NOT "${delimited}_" STREQUAL "_")
      set(rest "${input}")
      set(input "${delimited}")
      
      if(ignore_leading_whitespace)
        string_take_whitespace(input)
      endif()

      if(encode_input)
        uri_encode("${input}" 32)
        ans(input)
      endif()
    endif()

    

    # the whole uri is delimited by a space or end of string
    set(CMAKE_MATCH_1)
    set(CMAKE_MATCH_2)
    set(uri)
    if("_${input}" MATCHES "^_(${uric}+)(.*)")
      set(uri "${CMAKE_MATCH_1}")
      set(input "${CMAKE_MATCH_2}")
    endif()
    #string_take_regex(input "${uric}+")
    #ans(uri)

    if("${rest}_" STREQUAL "_")
      set(rest "${input}")
    endif()


    set(windows_absolute_path false)
    if(default_file_scheme)
      if(handle_windows_paths)
        # replace backward slash with forward slash
        # for windows paths - non standard behaviour
        string(REPLACE \\ /  uri "${uri}")
      endif()  


      if("_${uri}" MATCHES "^_/" AND NOT "_${uri}" MATCHES "^_//")
        set(uri "file://${uri}")
      endif()

      if("_${uri}" MATCHES "^_[a-zA-Z]:")
        #local windows path no scheme -> scheme is file://
        # <drive letter>: is replaced by /<drive letter>|/
        # also colon after drive letter is normalized to  ${driveletter_separator}
        string(REGEX REPLACE "^_([a-zA-Z]):(.+)" "\\1${driveletter_separator}\\2" uri "_${uri}")
        set(uri "file:///${uri}")
        set(windows_absolute_path true)
      endif()

    endif()
    
    # the rest is not part of input_uri
    map_capture(${input_uri} uri rest delimited_rest delimiters windows_absolute_path)
    return_ref(input_uri)

endfunction()






  function(uri_params_deserialize query)
      
    string(REPLACE "&" "\;" query_assignments "${query}")
    set(query_assignments ${query_assignments})
    string(ASCII 21 c)
    map_new()
    ans(query_data)
    foreach(query_assignment ${query_assignments})
      string(REPLACE "=" "\;"  value "${query_assignment}")
      set(value ${value})
      list_pop_front(value)
      ans(key)
      set(path "${key}")      

      string(REPLACE "[]" "${c}" path "${path}")      
      string(REGEX REPLACE "\\[([^0-9]+)\\]" ".\\1" path "${path}")
      string(REPLACE "${c}" "[]" path "${path}")


      uri_decode("${path}")
      ans(path)
      uri_decode("${value}")
      ans(value)  


      ref_nav_set("${query_data}" "!${path}" "${value}")

    endforeach()
    return_ref(query_data)
  endfunction()




  function(uri_params_serialize )
    function(uri_params_serialize_value)

      set(path ${path})
      list_pop_front(path)
      ans(first)


      set(res "${first}")
      foreach(part ${path})
        uri_encode("${part}")
        ans(part)
        set(res "${res}[${part}]")
      endforeach()

      uri_encode("${node}")
      ans(node)
      set(res "${res}=${node}")
      map_append(${context} assignments ${res})
    endfunction()
   map()
    kv(value uri_params_serialize_value)
   end()
  ans(callbacks)
  function_import_table(${callbacks} uri_params_serialize_callback)

  # function definition
  function(uri_params_serialize obj )
    obj("${obj}")
    ans(obj)  
    map_new()
    ans(context)
    dfs_callback(uri_params_serialize_callback ${obj})
    map_tryget(${context} assignments)
    ans(assignments)
    string_combine("&" ${assignments})
    return_ans()  
  endfunction()
  #delegate
  uri_params_serialize(${ARGN})
  return_ans()
  endfunction()




## parses an uri
## input can be any path or uri
## whitespaces in segments are allowed if string is delimited by double or single quotes(non standard behaviour)
##{
#  scheme,
#  net_root: # is // if the uri is a net uri
#  authority: # is the authority part if uri has a net_root
#  abs_root: # is / if the uri is a absolute path
#  segments: # an array of uri segments (folder)
#  file: # the last segment 
#  file_name: # the last segment without extension 
#  extension: # extension of file 
#  rest: # the ret of the input string which is not part of the uri
#  query: # the query part of the uri 
#  fragment # fragment part of uri
# }
##
##
##
function(uri_parse str)
  set(flags ${ARGN})

  list_extract_labelled_value(flags --into-existing)
  ans(res)
  list_extract_flag(flags --basic)
  ans(basic)
  list_extract_flag(flags --notnull)
  ans(notnull)
  if(notnull)
    set(notnull --notnull)
  else()
    set(notnull)
  endif()


  regex_uri()



  # set input data for uri
  if(NOT res)
    map_new()
    ans(res)
  endif()


  map_set(${res} input "${str}")


  ## normalize input of uri
  uri_normalize_input("${res}" ${flags})
  map_get("${res}" uri)
  ans(str)
  # scheme
  set(CMAKE_MATCH_1)
  set(CMAKE_MATCH_2)
  if("_${str}" MATCHES "^_(${scheme_regex})${scheme_delimiter}(.*)")
    set(scheme "${CMAKE_MATCH_1}")
    set(str "${CMAKE_MATCH_2}")
  else()
    set(scheme)
  endif()
  #string_take_regex(str "${scheme_regex}:")
  #ans(scheme)

  #if(NOT "${scheme}_"  STREQUAL _)
  #  string_slice("${scheme}" 0 -2)
  #  ans(scheme)
  #endif()

  # scheme specic part is rest of uri
  set(scheme_specific_part "${str}")


  # net_path
  set(net_path)
  set(authority)
  set(CMAKE_MATCH_1)
  set(CMAKE_MATCH_2)
  if("_${str}" MATCHES "^_(${net_root_regex})(.*)")
    set(net_path "${CMAKE_MATCH_1}")
    set(str "${CMAKE_MATCH_2}")
    set(CMAKE_MATCH_1)
    set(CMAKE_MATCH_2)
    if("_${str}" MATCHES "^_(${authority_regex})(.*)")
      set(authority "${CMAKE_MATCH_1}")
      set(str "${CMAKE_MATCH_2}")
    endif()
  endif()
  #string_take_regex(str "${net_root_regex}")
  #ans(net_path)

  # authority
#  set(authority)
 # if(net_path)
  #  string_take_regex(str "${authority_regex}")
   # ans(authority)
 # endif()

  set(path)
  set(CMAKE_MATCH_1)
  set(CMAKE_MATCH_2)
  if("_${str}" MATCHES "^_(${path_char_regex}+)(.*)")
    set(path "${CMAKE_MATCH_1}")
    set(str "${CMAKE_MATCH_2}")
  endif()




  if(net_path)
    set(net_path "${authority}${path}")
  endif()


 # string_take_regex(str "${path_char_regex}+")
 # ans(path)

  set(query)
  set(CMAKE_MATCH_1)
  set(CMAKE_MATCH_2)
  if("_${str}" MATCHES "^_${query_delimiter}(${query_char_regex}*)(.*)")
    set(query "${CMAKE_MATCH_1}")
    set(str "${CMAKE_MATCH_2}")
  endif()
  #string_take_regex(str "${query_regex}")
  #ans(query)
  #if(query)
  #  string_slice("${query}" 1 -1)
  #  ans(query)
  #endif()

  set(CMAKE_MATCH_1)
  set(CMAKE_MATCH_2)
  set(fragment)
  if("_${str}" MATCHES "^_${fragment_delimiter_regex}(${fragment_char_regex}*)(.*)")
    set(fragment "${CMAKE_MATCH_1}")
    set(str "${CMAKE_MATCH_2}")
  endif()

  #string_take_regex(str "${fragment_regex}")
  #ans(fragment)
  #if(fragment)
  #  string_slice("${fragment}" 1 -1)
  #  ans(fragment)
  #endif()


  map_capture(${res}
    
    scheme 
    scheme_specific_part
    net_path
    authority 
    path      
    query 
    fragment 

    ${notnull}
  )


  if(NOT basic)
    # extended parse
    uri_parse_scheme(${res})
    uri_parse_authority(${res})
    uri_parse_path(${res})
    uri_parse_file(${res})
    uri_parse_query(${res})      
  endif()


  return_ref(res)

endfunction()




function(uri_parse_authority uri)
  map_get(${uri} authority)
  ans(authority)

  map_get(${uri} net_path)
  ans(net_path)

  ## set authoirty to localhost if no other authority is specified but it is a net_path (starts wth //)
  if("_authority" STREQUAL "_" AND NOT "${net_path}_" STREQUAL "_")
    set(authority localhost)
  endif()

  dns_parse("${authority}")
  ans(dns)


  map_iterator(${dns})
  ans(it)
  while(true)
    map_iterator_break(it)
    if(NOT "${it.key}" STREQUAL "rest")
      map_set(${uri} ${it.key} ${it.value})
    endif()
  endwhile()

  return()

endfunction()







  ## expects last_segment property to exist
  ## ensures file_name, file, extension exists
  function(uri_parse_file uri)
    map_get("${uri}" last_segment)
    ans(file)

    if("_${file}" MATCHES "\\.") # file contains an extension
      string(REGEX MATCH "[^\\.]+$" extension "${file}")
      string(LENGTH "${extension}" extension_length)

      if(extension_length)
        math(EXPR extension_length "0 - ${extension_length}  - 2")
        string_slice("${file}" 0 ${extension_length})
        ans(file_name)
      endif()
    else()
      set(file_name "${file}")
      set(extension "")
    endif()
    map_capture(${uri} file extension file_name)
  endfunction()





  function(uri_parse_path uri)
    map_get("${uri}" path)
    ans(path)    

    set(segments)
    set(encoded_segments)
    set(last_segment)
    string_take_regex(path "${segment_separator_char}")
    ans(slash)
    set(leading_slash ${slash})

    while(true) 
      string_take_regex(path "${segment_char}+" )
      ans(segment)

  


      if("${segment}_" STREQUAL "_")
        break()
      endif()

      string_take_regex(path "${segment_separator_char}")
      ans(slash)


      list(APPEND encoded_segments "${segment}")

      uri_decode("${segment}")
      ans(segment)
      list(APPEND segments "${segment}")
      set(last_segment "${segment}")
    endwhile()


    set(trailing_slash "${slash}")


    set(normalized_segments)
    set(current_segments ${segments})   

    while(true)
      list_pop_front(current_segments)
      ans(segment)

      if("${segment}_" STREQUAL "_")
        break()
      elseif("${segment}" STREQUAL ".")

      elseif("${segment}" STREQUAL "..")
        list(LENGTH normalized_segments len)

        list_pop_back(normalized_segments)
        ans(last)
        if("${last}" STREQUAL ".." )
          list(APPEND normalized_segments .. ..)
        elseif("${last}_" STREQUAL "_" )
          list(APPEND normalized_segments ..)
        endif()
      else()
        list(APPEND normalized_segments "${segment}")
      endif()
    endwhile()

    if(("${segments}_" STREQUAL "_") AND leading_slash)
      set(trailing_slash "")
    endif()


    map_capture(${uri} segments encoded_segments last_segment trailing_slash leading_slash normalized_segments)
    return()
  endfunction()




## parses the query field of uri and sets  the uri.params field to the parsed data
function(uri_parse_query uri)
  map_tryget(${uri} query)
  ans(query)
  uri_params_deserialize("${query}")
  ans(params)
  map_set(${uri} params ${params})
  return()

endfunction()




function(uri_parse_scheme uri)
  map_tryget(${uri} scheme)
  ans(scheme)

  string(REPLACE "+" "\;" schemes "${scheme}")
  map_set(${uri} schemes ${schemes})

endfunction()





  ## tries to interpret the uri as a local path and replaces it 
  ## with a normalized local path (ie file:// ...)
  ## returns a new uri
  function(uri_qualify_local_path uri)
    uri("${uri}")
    ans(uri)

    map_tryget(${uri} input)
    ans(uri_string)

    map_tryget(${uri} normalized_host)
    ans(normalized_host)

    map_tryget("${uri}" scheme)
    ans(scheme)


    ## check if path path is going to be local
    eval_truth(
       "${scheme}_" MATCHES "(^_$)|(^file_$)" # scheme is file
       AND normalized_host STREQUAL "localhost" # and host is localhost 
       AND NOT "${uri_string}" MATCHES "^[^/]+:" # and input uri is not scp like ssh syntax
     ) 
    ans(is_local)

    ## special handling of local path
    if(is_local)
      ## use the locally qualfied full path
      map_get("${uri}" path)
      ans(local_path)
      path_qualify(local_path)
      map_tryget(${uri} params)
      ans(params)
      uri("${local_path}")
      ans(uri)
      map_set("${uri}" params "${params}")
    endif()
    return_ref(uri)
  endfunction()





## characters specified in rfc2396
## 37 %  (percent)
## 126 ~ (tilde) 
## 1-32 (control chars) (nul is not allowed) 
## 127 (del)
## 32 (space)
## 35 (#) sharp fragment identifer
## 60 (<) 62 (>) 34 (") delimiters 
## unwise 
## 123 { 125 } 124 | 92 \ 94 ^ 91 [ 93 ] 96 `

function(uri_recommended_to_escape)
  ## control chars
  index_range(1 31)
  ans(dec_codes)

  
  list(APPEND dec_codes 
    32   # space
    34   # "
    35   # #
    60   # <
    62   # >
    91   # [
    93   # ]
    94   # ^ 
    96   # ` 
    123  # {
    124  # |
    125  # }
    127  # del
    )

  set(dec_codes
      37   # %  (this is prepended - important in uri_encode )
      ${dec_codes}
      )
  return_ref(dec_codes)



endfunction()




  function(uri_remove_schemes uri)
    uri("${uri}")
    ans(uri)
    map_tryget(${uri} schemes)
    ans(schemes)
    list_remove(schemes ${ARGN})
    map_set(${uri} schemes)
    list_combine("+" ${schemes})
    ans(scheme)
    map_tryget(${uri} scheme)
    return_ref(uri)
  endfunction()

  function(uri_set_schemes uri)
    uri("${uri}")
    ans(uri)
    


    map_set(${uri} schemes ${ARGN})

    list_combine("+" ${ARGN})
    ans(scheme)

    map_tryget("${uri}" scheme)
    ans(old_scheme)

    map_set("${uri}" scheme "${scheme}")


    map_tryget(${uri} uri)
    ans(uri_string)

    if(NOT old_scheme)
        set(uri_string "${scheme}:${uri_string}" )
    else()
        string(REPLACE "${old_scheme}:" "${scheme}:" uri_string "${uri_string}")
    endif()

    map_set(${uri} uri "${uri_string}")
    return_ref(uri)
  endfunction()

  function(uri_add_schemes uri)

    uri("${uri}")
    ans(uri)

    map_tryget(${uri} schemes)
    ans(schemes)

    set(schemes ${ARGN} ${schemes})
    list_remove_duplicates(schemes)

    uri_set_schemes(${uri} ${schemes})
    return_ans()

  endfunction()




## formats an <uri~> to a localpath 
function(uri_to_localpath uri)
  uri("${uri}")
  ans(uri)

  map_tryget("${uri}" normalized_segments)
  ans(segments)

  map_tryget(${uri} leading_slash)
  ans(rooted)

  map_tryget(${uri} trailing_slash)
  ans(trailing_slash)

  map_tryget(${uri} windows_absolute_path)
  ans(windows_absolute_path)

  string_combine("/" ${segments})
  ans(path)

  if(WIN32 AND "${path}" MATCHES "^[a-zA-Z]:")
    # do nothing
  elseif(rooted AND NOT windows_absolute_path)
    set(path "/${path}")
  endif()
  set(path "${path}${trailing_slash}")
  return_ref(path)
endfunction()






  function(value)
    set(value ${ARGN})

    if("${value}_" STREQUAL "_")
      return()
    endif()

    set(callable)
    set(is_callable false)


    is_lambda("${ARGV0}")
    ans(is_lambda)

    if(COMMAND "${ARGV0}")
      list(REMOVE_AT value 0)
      callable("${ARGV0}")
      ans(callable)
      set(is_callable true)
    elseif(is_lambda)
      list(REMOVE_AT value 0)
      callable("${ARGV0}")
      ans(callable)
      set(is_callable true)
    else()
      is_callable("${ARGV0}")
      ans(is_callable)
      if(is_callable)
        set(callable "${ARGV0}")
      endif()
    endif()
    if(is_callable)
      call2("${callable}" ${value})
      return_ans()
    endif()

    data(${value})
    return_ans()
  endfunction()





function(git)
  find_package(Git)
  if(NOT GIT_FOUND)
    message(FATAL_ERROR "missing git")
  endif()

  wrap_executable(git "${GIT_EXECUTABLE}")
  git(${ARGN})
  return_ans()


endfunction()  






## returns the git base dir (the directory in which .git is located)
function(git_base_dir)  
  git_dir("${ARGN}")
  ans(res)
  path_component("${res}" --parent-dir)
  ans(res)
  return_ref(res)
endfunction()




  ## git_cached_clone(<remote uri:<~uri>> <?target_dir> [--readonly] ([--file <>]|[--read<>]) [--ref <git ref>])-> 
    function(git_cached_clone remote_uri)
      set(args ${ARGN})


      list_extract_flag(args --readonly)
      ans(readonly)
      
      list_extract_labelled_value(args --ref)
      ans(git_ref)

      list_extract_labelled_value(args --file)
      ans(file)

      list_extract_labelled_value(args --read)
      ans(read)

      list_pop_front(args)
      ans(target_dir)


      path_qualify(target_dir)

      cmakepp_config(cache_dir)
      ans(cache_dir)

      string(MD5 cache_key "${remote_uri}" )

      set(repo_cache_dir "${cache_dir}/git_cache/${cache_key}")

      if(NOT EXISTS "${repo_cache_dir}")
        git_lean(clone --mirror "${remote_uri}" "${repo_cache_dir}")
        ans_extract(error)
        if(error)
          rm("${repo_cache_dir}")
          message(FATAL_ERROR "git could not clone ${remote_uri}")
        endif()

      endif()
      set(result)
      pushd("${repo_cache_dir}")
        set(ref "${git_ref}")
        if(NOT ref)
          set(ref "HEAD")
        endif()
        if(read OR file)
          git_lean(fetch)
          ans_extract(error)
          if(error)
            message(FATAL_ERROR "failed to fetch")
          endif()

          git_lean(show "${ref}:${read}")
          ans_extract(error)
          ans(git_result)

          if(NOT error)
            set(result "${git_result}")
            if(file)
              set(target_path "${target_dir}/${file}")
              fwrite("${target_path}" "${git_result}")
              set(result "${target_path}")
            endif()
          endif()
        else()
          git_lean(clone --reference "${repo_cache_dir}" "${remote_uri}" "${target_dir}")
          ans_extract(error)
          if(error)
            message(FATAL_ERROR "failed to reference clone")
          endif()
          pushd("${target_dir}")
            git_lean(checkout "${git_ref}")
            ans_extract(error)
            if(error)
              message(FATAL_ERROR "failed to checkout ${git_ref}")
            endif()
            git_lean(submodule init)
            ans_extract(error)
            if(error)
              message(FATAL_ERROR "failed to init submodules for  ${git_ref}")
            endif()
            git_lean(submodule update)
            ans_extract(error)
            if(error)
              message(FATAL_ERROR "failed to update submodules for  ${git_ref}")
            endif()
          popd()   
          set(result "${target_dir}")
        endif()
       popd()

      return_ref(result)      

    endfunction()





# returns the git directory for pwd or specified path
function(git_dir)
  set(path ${ARGN})
  path("${path}")
  ans(path)
  message("${path}")

  pushd("${path}")
  git(rev-parse --show-toplevel)
  ans(res)
  message("${res}")
  
  popd()
  string(STRIP "${res}" res)
  set(res "${res}/.git")
  message("${res}")
  return_ref(res)
endfunction()





## `(<args...>)`[<exitcode>, <stdout>]
##
## a lean wrapper for git
## does not take part in the process management of cmakepp
function(git_lean)
  find_package(Git)
  if(NOT GIT_FOUND)
    message(FATAL_ERROR "missing git")
  endif()

  wrap_executable_bare(git_lean "${GIT_EXECUTABLE}")
  git_lean(${ARGN})
  return_ans()


endfunction()




# reads a single file from a git repository@branch using the 
# repository relative path ${path}. returns the contents of the file
function(git_read_single_file repository branch path )
  mktemp()
  ans(tmp_dir)

  set(branch_arg)
  if(branch)
    set(branch_arg --branch "${branch}") 
  endif()

  git_lean(clone --no-checkout ${branch_arg} --depth 1 "${repository}" "${tmp_dir}")
  ans_extract(error)

  if(error)
    rm(-r "${tmp_dir}")
    popd()
    return()
  endif()

  if(NOT branch)
    set(branch HEAD)
  endif()


  pushd("${tmp_dir}")
  git_lean(show --format=raw "${branch}:${path}")
  ans_extract(error)
  ans(res)

  popd()


  popd()
  rm(-r "${tmp_dir}")

  
  if(error)
    return()
  endif()
  

  return_ref(res)
  
endfunction()




# parses a git ref and retruns a map with the fields type and name
function(git_ref_parse  ref)
  set(res)
  if(${ref} STREQUAL HEAD)
    map_new()
    ans(res)
    map_set(${res} type HEAD)
    map_set(${res} name HEAD)
  endif()
  if("${ref}" MATCHES "^refs/([^/]*)/(.*)$")
    string(REGEX REPLACE "^refs/([^/]*)/(.*)$" "\\1;\\2" parts "${ref}")
    list_extract(parts type name)
    map_new()
    ans(res)
    map_set(${res} type ${type})
    map_set(${res} name ${name})
  endif()
  return_ref(res)
endfunction()




# registers a git hook
function(git_register_hook hook_name)
  git_directory()
  ans(git_dir)


endfunction()


function(git_local_hooks)
  set(hooks
    pre-commit
    post-commit
    prepare-commit-msg
    commit-msg
    pre-rebase
    post-checkout

    )
  return_ref(hooks)

endfunction()






# checks wether the uri is a remote git repository
function(git_remote_exists uri)
  git_uri("${uri}")
  ans(uri)


  git_lean(ls-remote "${uri}")
  ans_extract(error)
  
  if(error)
    return(false)
  endif()
  return(true)
endfunction()





# checks the remote uri if a ref exists ref_type can be * to match any
# else it can be tags heads or HEAD
function(git_remote_has_ref uri ref_name ref_type)
  git_remote_ref("${uri}" "${ref_name}" "${ref_type}")
  ans(res)
  if(res)
    return(true)
  else()
    return(false)
  endif()

endfunction()








# checks the remote uri if a ref exists ref_type can be * to match any
# else it can be tags heads or HEAD
# returns the corresponding ref object
function(git_remote_ref uri ref_name ref_type)
  git_remote_refs( "${uri}")
  ans(refs)
  foreach(current_ref ${refs})
    map_navigate(name "current_ref.name")
    if("${name}" STREQUAL "${ref_name}")
      if(ref_type STREQUAL "*")
        return(${current_ref})
      else()
        map_navigate(type "current_ref.type")
        if(${type} STREQUAL "${ref_type}")
          return("${current_ref}")
        endif()
        return()
      endif()
    endif()
  endforeach()
  return()
endfunction()







# returns a list of ref maps containing the fields 
# name type and revision
function(git_remote_refs uri)
  git_uri("${uri}")
  ans(uri)

  git_lean(ls-remote ${uri})
  ans_extract(error)
  ans(stdout)

  if(error)
    return()
  endif()

  string_split( "${stdout}" "\n")
  ans(lines)
  set(res)
  foreach(line ${lines})
    string(STRIP "${line}" line)

    # match
    if("${line}" MATCHES "^([0-9a-fA-F]*)\t(.*)$")
      string(REGEX REPLACE "^([0-9a-fA-F]*)\t(.*)$" "\\1;\\2" parts "${line}")
      list_extract(parts revision ref)
      git_ref_parse("${ref}")
      ans(ref_map)
      
      map_set("${ref_map}" uri "${uri}")
      if(ref_map)
        map_set(${ref_map} revision ${revision})
        set(res ${res} ${ref_map})
        #address_print(${ref_map})
      endif()
    endif()
  endforeach()   
  return_ref(res)
endfunction()




function(git_repository_name repository_uri)
  get_filename_component(repo_name "${repository_uri}" NAME_WE)
  return("${repo_name}")
endfunction()





    function(git_scm_descriptor git_ref)

        set(scm_descriptor)
        assign(!scm_descriptor.scm = 'git')
        assign(!scm_descriptor.ref = git_ref)

        return_ref(scm_descriptor)
    endfunction()




## returns the git uri for the given ARGN
## if its empty emtpy is returned
## if it exists it is returned
## if it exists after qualification the qualifed path is returned
## else it is retunred
function(git_uri)

  set(uri ${ARGN})
  if(NOT uri)
    return()
  endif()
  if(EXISTS "${uri}")
    return("${uri}")
  endif()
  path("${uri}")
  ans(uri_path)
  if(EXISTS "${uri_path}")
    return_ref(uri_path)
  endif()
  return_ref(uri)
endfunction()







# convenience function for accessing hg
# use cd() to navigate to working directory
# usage is same as hg command line client
# syntax differs: hg arg1 arg2 ... -> hg(arg1 arg2 ...)
# add a --process-handle flag to get a object containing return code
# input args etc.
# else only console output is returned
function(hg)
  find_package(Hg)
  if(NOT HG_FOUND)
    message(FATAL_ERROR "mercurial is not installed")
  endif()

   wrap_executable(hg "${HG_EXECUTABLE}")
   hg(${ARGN})
   return_ans()

endfunction()




## hg_cached_clone(<remote_uri:<~uri>> <?target_dir> [--ref <ref>] [--readonly] [--file <rel path>] [--read <rel path>])
##
## performs a cached clone from the specified remote uri
##
  function(hg_cached_clone remote_uri)
      set(args ${ARGN})
      
      ### extract options
      list_extract_labelled_value(args --ref)
      ans(ref)

      list_extract_flag(args --readonly)
      ans(readonly)

      list_extract_labelled_value(args --file)
      ans(file)

      list_extract_labelled_value(args --read)
      ans(read)

      if(file AND read)
        message(FATAL_ERROR "--file and --read is not allowed")
      endif() 

      list_pop_front(args)
      ans(target_dir)

      path_qualify(target_dir)

      ## create a cache directory for the uri
      cmakepp_config(cache_dir)
      ans(cache_dir)

      string(MD5 cache_key "${remote_uri}")

      set(repo_cache_dir "${cache_dir}/hg_cache/${cache_key}")

      ## initial clone of repo 
      if(NOT EXISTS "${repo_cache_dir}")
        hg(clone "${remote_uri}" "${repo_cache_dir}" --exit-code)
        ans(error)
        if(error)
          rm("${repo_cache_dir}")
          message(FATAL_ERROR "hg could not clone ${remote_uri} - failed with ${error}")
        endif()
      endif()

      # update cached repo then copy it over to the target dir
      # where the correct revision is checked out
      pushd("${repo_cache_dir}")

        hg(update)

        if(file OR read)
          set(path ${file} ${read})
          if(ref)
            set(ref "-r${ref}")
          endif()

          hg(cat ${ref} "${path}" --process-handle)
          ans(hg_result)
          assign(error = hg_result.exit_code)
          if(NOT error)
            assign(result = hg_result.stdout)
            if(file)
              fwrite("${target_dir}/${path}" "${result}")
              set(result "${target_dir}/${path}")
            endif()
          endif()
        elseif(readonly)
          set(result ${repo_cache_dir})
        else()
          cp_dir("${repo_cache_dir}" "${target_dir}")
          pushd("${target_dir}")
            hg(checkout "${ref}")
          popd()
          set(result "${target_dir}")
        endif()
      popd()

      return_ref(result)
    endfunction()





 function(hg_constraint)
  map_has_all("${ARGN}" uri branch)
  ans(is_hg_constraint)
  if(is_hg_constraint)
    return("${ARGN}")
  endif() 

  package_query("${ARGN}")
  ans(pq)

  map_new()
  ans(constraint)
  nav(hg_constraint = pq.package_constraint)

  string_split_at_last(repo_uri branch "${hg_constraint}" "@")
  if(NOT branch)
    set(branch "default")
  endif()
  map_set(${constraint} uri "${repo_uri}")
  map_set(${constraint} "branch" ${branch})
  return (${constraint})
 endfunction()

 
function(line_info)
  set(t1 ${CMAKE_CURRENT_LIST_FILE})
  set(t2 ${CMAKE_CURRENT_LIST_LINE})
  obj("{
    file:$t1,
    line:$t2
    }")

  json_print(${__ans})
endfunction()





function(hg_get_refs)
  hg(branches)
  ans(branches)
  string_split("${branches}" "\n")
  hg(tags)
  ans(tags)  
  string_split("${tags}" "\n")
  ans(tags)


  set(refs)
  foreach(ref ${tags}  )
    hg_parse_ref("${ref}")
    ans(ref)
    map_set("${ref}" type "tag")
    list(APPEND refs "${ref}") 
  endforeach()
  foreach(ref ${branches}  )
    hg_parse_ref("${ref}" )
    ans(ref)
    map_set("${ref}" type "branch")
    list(APPEND refs "${ref}") 
  endforeach()
  return_ref(refs)
endfunction()







function(hg_match_refs search)
  hg_get_refs()
  ans(refs)


  list_match(refs "{name:$search}")
  ans(m1)

  list_match(refs "{number:$search}")
  ans(m2)
  list_match(refs "{hash:$search}")
  ans(m3)
  list_match(refs "{type:$search}")
  ans(m4)
  set(res ${m1} ${m2} ${m3} ${m4})
  return_ref(res)
endfunction()





# parses a hg ref (e.g. result of hg tags ) returning a map
# { name: <identifier>, number:<int>, id:<hash>}
function(hg_parse_ref)
 string(REGEX REPLACE "^_([a-zA-Z0-9_\\.\\/\\-]+)[ ]+([0-9]+):([0-9a-fA-F]+)(.*)$" "\\1;\\2;\\3;\\4" parts "_${ref}")
  map_new()
  ans(ref_struct)
  list_extract(parts name rev_number rev rest)
  if("${rest}" MATCHES "\\(inactive\\)")
    map_set(${ref_struct} inactive true)
  else()
    map_set(${ref_struct} inactive false)
  endif()


  map_set(${ref_struct} name "${name}")
  map_set(${ref_struct} number "${rev_number}")
  map_set(${ref_struct} hash "${rev}")
  return_ref(ref_struct)
endfunction()






function(hg_ref  search)
  hg_match_refs("${search}")
  ans(res)
  list(LENGTH res len)
  if("${len}" EQUAL 1)
    return(${res})
  endif()
  return()
endfunction()






# returns true iff the uri is a hg repository
function(hg_remote_exists uri)
  hg(identify "${uri}" --exit-code)
  ans(error)

  if(NOT error)
    return(true)
  endif()
  return(false)
endfunction()






function(hg_repository_name repository_uri)
  get_filename_component(repo_name "${repository_uri}" NAME_WE)
  return("${repo_name}")
endfunction()





  ## `(<path=".">)->"git"|"svn"|"hg"|<null>`
  ##
  ## returns the scm found `"git"|"svn"|"hg"` in specified directory
  function(scm_which)
    message(FATAL_ERROR notimplemented)
    path("${ARGN}")
    ans(path)
    pushd("${path}")
      git(status --exit-code)
      ans(error)
      if(NOT error)
        popd()
        return(git)
      endif()
      hg(status --exit-code)
      ans(error)
      if(NOT error)
        popd()
        return(hg)
      endif()
      svn(info --depth=empty)
      ans(result)

      if(NOT "${result}_" STREQUAL "_" )
        popd()
        return(svn)
      endif()
    popd()
    return()
  endfunction()




# convenience function for accessing subversion
# use cd() to navigate to working directory
# usage is same as svn command line client
# syntax differs: svn arg1 arg2 ... -> svn(arg1 arg2 ...)
# also see wrap_executable for usage
# add a --process-handle flag to get a object containing return code, output
# input args etc.
# add --exit-code flag to get the return code of the commmand
# by default fails if return code is not 0 else returns  stdout/stderr
function(svn)
  find_package(Subversion)
  if(NOT SUBVERSION_FOUND)
    message(FATAL_ERROR "subversion is not installed")
  endif()
  # to prohibit non utf 8 decode errors
  set(ENV{LANG} C)
  set(ENV{LC_MESSAGES} C)
  
  wrap_executable(svn "${Subversion_SVN_EXECUTABLE}")
  
  svn(${ARGN})
  return_ans()
endfunction()




## svn_cached_checkout()
function(svn_cached_checkout uri)
  set(args ${ARGN})
  path_qualify(target_dir)

  list_extract_flag(args --refresh)
  ans(refresh)
  
  list_extract_flag(args --readonly)
  ans(readonly)


  list_extract_labelled_keyvalue(args --revision)
  ans(revision)
  list_extract_labelled_keyvalue(args --branch)
  ans(branch)
  list_extract_labelled_keyvalue(args --tag)
  ans(tag)

  list_pop_front(args)
  ans(target_dir)
  path_qualify(target_dir)

  
  svn_uri_analyze(${uri} ${revision} ${branch} ${tag})
  ans(svn_uri)

  map_import_properties(${svn_uri} base_uri ref_type ref revision relative_uri)

  if(NOT revision)
    set(revision HEAD)
  endif()


  if("${ref_type}" STREQUAL "branch")
    set(ref_type branches)
  elseif("${ref_type}" STREQUAL "tag")
    set(ref_type tags)
  endif()
  
  cmakepp_config(cache_dir)
  ans(cache_dir)

  string(MD5 cache_key "${base_uri}@${revision}@${ref_type}@${ref}")
  set(cached_path "${cache_dir}/svn_cache/${cache_key}")
  
  if(EXISTS "${cached_path}" AND NOT refresh)
    if(readonly)
      return_ref(cached_path)
    else()
      cp_dir("${cached_path}" "${target_dir}")
      return_ref(target_dir)
    endif()
  endif()

  set(checkout_uri "${base_uri}/${ref_type}/${ref}@${revision}")
  svn_remote_exists("${checkout_uri}")
  ans(remote_exists)
  
  if(NOT remote_exists)
    return()
  endif()


  if(EXISTS "${cached_path}")
    rm("${cached_path}")
  endif()
  mkdir("${cached_path}")


  svn(checkout "${checkout_uri}" "${cached_path}" --non-interactive  --exit-code)
  ans(error)

  if(error)
    rm("${cached_path}")
    return()
  endif()

  if(readonly)
    return_ref(cached_path)
  else()
    cp_dir("${cached_path}" "${target_dir}")
    return_ref(target_dir)
  endif()
endfunction()






## returns the revision for the specified svn uri
function(svn_get_revision)
  svn_info("${ARGN}")
  ans(res)
  nav(res.revision)
  return_ans()
endfunction()




## returns an info object for the specified svn url
## {
##    path:"path",
##    revision:"revision",
##    kind:"kind",
##    url:"url",
##    root:"root",
##    uuid:"uuid",
## }
## todo: cached?
function(svn_info uri)
    svn_uri("${uri}")
    ans(uri)


    svn(info ${uri} --process-handle --xml ${ARGN})
    ans(res)
    map_tryget(${res} exit_code)
    ans(error)
    if(error)
      return()
    endif()

    map_tryget(${res} stdout)
    ans(xml)

    xml_parse_attrs("${xml}" entry path)    
    ans(path)
    xml_parse_attrs("${xml}" entry revision)    
    ans(revision)
    xml_parse_attrs("${xml}" entry kind)    
    ans(kind)
    xml_parse_values("${xml}" url)
    ans(url)
    xml_parse_values("${xml}" root)
    ans(root)
    xml_parse_values("${xml}" relative-url)
    ans(relative_url)

    string(REGEX REPLACE "^\\^/" "" relative_url "${relative_url}")

    xml_parse_values("${xml}" uuid)
    ans(uuid)
    map()
      var(path revision kind url root uuid relative_url)
    end()
    ans(res)
    return_ref(res)
endfunction()




## returns true if a svn repository exists at the specified location
  function(svn_remote_exists uri)
    svn(ls "${uri}" --depth empty --non-interactive --exit-code)
    ans(error)
    if(error)
      return(false)
    endif()
    return(true)
  endfunction()




## returns the svn_uri for the given ARGN
## if its empty emtpy is returned
## if it exists it is returned
## if it exists after qualification the qualifed path is returned
## else it is retunred
function(svn_uri)

  set(uri ${ARGN})
  if(NOT uri)
    return()
  endif()
  if(EXISTS "${uri}")
    return("${uri}")
  endif()
  path("${uri}")
  ans(uri_path)
  if(EXISTS "${uri_path}")
    return_ref(uri_path)
  endif()
  return_ref(uri)
endfunction()







  ## svn_uri_analyze(<input:<?uri>> [--revision <rev>] [--branch <branch>] [--tag <tag>])-> 
  ## {
  ##   input: <string>
  ##   uri: <uri string>
  ##   base_uri: <uri string>
  ##   relative_uri: <path>
  ##   ref_type: "branch"|"tag"|"trunk"
  ##   ref: <string>
  ##   revision: <rev>
  ## }
  ##
  ## 
  function(svn_uri_analyze input)
    set(args ${ARGN})

    list_extract_labelled_value(args --revision)
    ans(args_revision)
    list_extract_labelled_value(args --branch)
    ans(args_branch)
    list_extract_labelled_value(args --tag)
    ans(args_tag)

    uri("${input}")
    ans(uri)


    assign(params_revision = uri.params.rev)
    assign(params_branch = uri.params.branch)
    assign(params_tag = uri.params.tag)

    set(trunk_dir trunk)
    set(tags_dir tags)
    set(branches_dir branches)

    uri_format(${uri} --no-query)
    ans(formatted_uri)

    set(uri_revision)
    if("${formatted_uri}" MATCHES "@(([1-9][0-9]*)|HEAD)(\\?|$)")
      set(uri_revision "${CMAKE_MATCH_1}")
      string(REGEX REPLACE "@${uri_revision}" "" formatted_uri "${formatted_uri}")
    endif()

    set(CMAKE_MATCH_3)
    set(uri_ref)
    set(base_uri "${formatted_uri}")
    set(uri_tag)
    set(uri_branch)
    set(uri_rel_path)
    set(uri_ref_type)
    set(ref_type)
    set(ref)
    if("${formatted_uri}" MATCHES "(.*)/(${trunk_dir}|${tags_dir}|${branches_dir})(/|$)")
      set(base_uri "${CMAKE_MATCH_1}")
      set(uri_ref_type "${CMAKE_MATCH_2}")

      set(uri_rel_path "${formatted_uri}")
      string_take(uri_rel_path "${base_uri}/${uri_ref_type}")
      string_take(uri_rel_path "/")

      if(uri_ref_type STREQUAL "${tags_dir}" OR uri_ref_type STREQUAL "${branches_dir}")
        string_take_regex(uri_rel_path "[^/]+")
        ans(uri_ref)
      endif()
      
      if(uri_ref_type STREQUAL "${branches_dir}")
        set(uri_branch ${uri_ref})
      endif()
      if(uri_ref_type STREQUAL "${tags_dir}")
        set(uri_tag "${uri_ref}")
      endif()      

    endif()



    set(revision ${args_revision} ${params_revision} ${uri_revision})
    list_peek_front(revision)
    ans(revision)



    if(uri_ref_type STREQUAL "trunk")
      set(ref_type trunk)
      set(ref trunk)
    endif()

    if(uri_ref_type STREQUAL "branches")
      set(ref_type branch)
      set(ref ${uri_ref})
    endif()

    if(uri_ref_type STREQUAL "tags")
      set(ref_type tag)
      set(ref ${uri_ref})
    endif()

    
    if(args_branch)
      set(ref_type branch)
      set(ref ${args_branch})
    endif()

    if(args_tag)
      set(ref_type tag)
      set(ref ${args_tag})
    endif()

    if("${ref_type}_" STREQUAL "_")
      set(ref_type trunk)
      set(ref)
    endif()


    map_new()
    ans(result)
    map_set(${result} input ${input})
    map_set(${result} uri ${formatted_uri} )
    map_set(${result} base_uri "${base_uri}")
    map_set(${result} relative_uri "${uri_rel_path}")
    map_set(${result} ref_type "${ref_type}")
    map_set(${result} ref "${ref}")
    map_set(${result} revision "${revision}")

    return(${result})
  endfunction()





  function(svn_uri_format_package_uri svn_uri)
    map_import_properties(${svn_uri} base_uri revision ref ref_type)

    string(REGEX REPLACE "^svnscm\\+" "" base_uri "${base_uri}")

    if("${ref_type}" STREQUAL "branch")
      set(ref_type branches)
    elseif("${ref_type}" STREQUAL "tag")
      set(ref_type tags)
    endif()

    if(revision STREQUAL "HEAD")
      set(revision)
    endif() 


    set(params)
    if(NOT ref_type STREQUAL "trunk" OR revision)
      map_new()
      ans(params)
      if(NOT revision STREQUAL "")
        map_set(${params} rev "${revision}")
      endif()
      if(ref_type STREQUAL trunk)
      elseif("${ref_type}" STREQUAL "branch")
        map_set(${params} branch "${ref}")
      elseif("${ref_type}" STREQUAL "tag")
        map_set(${params} branch "${ref}")
      endif()
      uri_params_serialize(${params})
      ans(query)
      set(query "?${query}")
    endif()

    set(result "${base_uri}${query}")


    return_ref(result)


  endfunction()





  function(svn_uri_format_ref svn_uri)
    map_import_properties(${svn_uri} base_uri revision ref ref_type)

    string(REGEX REPLACE "^svnscm\\+" "" base_uri "${base_uri}")
    if(NOT revision)
      set(revision HEAD)
    endif()

    if("${ref_type}" STREQUAL "branch")
      set(ref_type branches)
    elseif("${ref_type}" STREQUAL "tag")
      set(ref_type tags)
    endif()
    
    set(checkout_uri "${base_uri}/${ref_type}/${ref}@${revision}")
    return_ref(checkout_uri)

  endfunction()





## bitbucket_api()
## 
## 
function(bitbucket_api)

  set(bitbucket_api_token)
 # if(NOT "$ENV{BITBUCKET_API_TOKEN}_" STREQUAL "_" )
 #   set(bitbucket_api_token "?client_id=$ENV{BITBUCKET_API_TOKEN}&client_secret=$ENV{GITHUB_DEVEL_TOKEN_SECRET}")
#  endif()
  set(api_uri "https://api.bitbucket.org/2.0")
  define_http_resource(bitbucket_api "${api_uri}/:path${bitbucket_api_token}")

  bitbucket_api(${ARGN})
  return_ans()
endfunction()






function(bitbucket_default_branch user repo)
  set(api_uri "https://bitbucket.org/api/1.0")
  set(query_uri "${api_uri}/repositories/${user}/${repo}/main-branch" )

  http_get("${query_uri}" --json --silent-fail)
  ans(response)

  if(NOT response)
    return()
  endif()

  map_tryget(${response} name)
  ans(res)
  return_ref(res)

endfunction()






    function(bitbucket_read_file user repo ref path)
      set(raw_uri "https://bitbucket.org/${user}/${repo}/raw/${ref}/${path}")
      http_get("${raw_uri}" "" --silent-fail)
      return_ans()
    endfunction()





  function(bitbucket_remote_ref user repo ref_type ref)
    set(api_uri "https://bitbucket.org/api/1.0")
    http_get("${api_uri}/repositories/${user}/${repo}/changesets/${ref}" --silent-fail --json)
    ans(bitbucket_response)
    if(NOT bitbucket_response)
      return()
    endif()
    map_tryget(${bitbucket_response} raw_node)
    ans(commit)
    map_capture_new(user repo ref_type ref commit bitbucket_response)
    return_ans()
  endfunction()





function(bitbucket_remote_refs user repo ref_type_query ref_name_query )
  set(api_uri "https://bitbucket.org/api/1.0")
  http_get("${api_uri}/repositories/${user}/${repo}/branches-tags" --silent-fail --json)
  ans(refs)
  if(NOT refs)
    return()
  endif()
  set(branches)
  set(tags)
  
  if("${ref_type_query}_" STREQUAL "*_" OR "${ref_type_query}_" STREQUAL "branches_")
    map_tryget(${refs} branches)
    ans(branches)
  endif()
  if("${ref_type_query}_" STREQUAL "*_" OR "${ref_type_query}_" STREQUAL "tags_")
    map_tryget(${refs} tags)
    ans(tags)
  endif()

  set(refs)

  foreach(branch ${branches})
    map_tryget(${branch} name)
    ans(ref)
    map_tryget(${branch} changeset)
    ans(commit)
    set(ref_type "branches")

    if("${ref_name_query}_" STREQUAL "*_" OR "${ref_name_query}_" STREQUAL "${ref}_")
      set(bitbucket_response ${branch})
      map_capture_new(user repo ref_type ref commit bitbucket_response)
      ans_append(refs)
    endif()
  endforeach()
  
  foreach(tag ${tags})
    map_tryget(${tag} name)
    ans(ref)
    map_tryget(${tag} changeset)
    ans(commit)
    set(ref_type "tags")  


    if("${ref_name_query}_" STREQUAL "*_" OR "${ref_name_query}_" STREQUAL "${ref}_")
      set(bitbucket_response ${tag})
      map_capture_new(user repo ref_type ref commit bitbucket_response)
      ans_append(refs)
    endif()

  endforeach()

  return_ref(refs)
endfunction()






  function(bitbucket_repositories user)
    set(result)

    set(api_uri "https://api.bitbucket.org/2.0")
    set(current_uri "${api_uri}/repositories/${user}")
    set(names)
    while(true)
      http_get("${current_uri}" --response)
      ans(response)
      assign(error = response.client_status)
      assign(current_result = response.content)
      if(error)
        error("failed to query ${current_uri} http client said: {response.client_message} ({response.client_status})}")
        return()
      endif()
      json_extract_string_value(next "${current_result}")
      ans(current_uri)
      json_extract_string_value(name "${current_result}")
      ans_append(names)

      if(NOT current_uri)
        break()
      endif()
    endwhile()

    list_remove_duplicates(names)
    list_remove(names ssh https) ## hack because of the way that json_extract_string_value works I have to remove other names
    
    return_ref(names)
  endfunction()




macro(check_host url)
 
  # expect webservice to be reachable
  http_get("${url}" --exit-code)
  ans(error)

  if(error)
    message("Test inconclusive webserver unavailable")
    return()
  endif()

endmacro()





  function(define_http_resource function uri_string)
    uri("${uri_string}")
    ans(uri)

    map_tryget("${uri}" scheme_specific_part)
    ans(scheme_specific_part)
    map_tryget("${uri}" scheme)
    ans(scheme)

    string(REGEX MATCHALL ":([a-zA-Z][a-zA-Z0-9_]*)" replaces "${scheme_specific_part}")

    list_remove_duplicates(replaces)

    set(function_args "")

    foreach(replace ${replaces})
      string(REGEX REPLACE ":([a-zA-Z][a-zA-Z0-9_]*)" "\\1" name "${replace}")
      string(REPLACE "${replace}" "\${${name}}" uri_string "${uri_string}")
      set(function_args "${function_args} ${name}")
    endforeach()    

    set(code "
      function(${function}${function_args})
        set(args \${ARGN})
        list_extract_flag(args --put)
        ans(put)
        set(resource_uri \"${uri_string}\")

        if(put)
          http_put(\"\${resource_uri}\" \${args})
        else()
          http_get(\"\${resource_uri}\" \${args})
        endif()
        return_ans()
      endfunction()
    ")
    eval("${code}")
    return()

  endfunction()




## download(uri [target] [--progress])
## downloads the specified uri to specified target path
## if target path is an existing directory the files original filename is kept
## else target is treated as a file path and download stores the file there
## if --progress is specified then the download progress is shown
## returns the path of the successfully downloaded file or null
function(download uri)
  set(args ${ARGN})

  set(uri_string "${uri}")
  uri("${uri}")
  ans(uri)


  list_extract_flag(args --progress)
  ans(show_progress)
  if(show_progress)
    set(show_progress SHOW_PROGRESS)
  else()
    set(show_progress)
  endif()

  list_pop_front(args)
  ans(target_path)
  path_qualify(target_path)

  map_tryget("${uri}" file)
  ans(filename)

  if(IS_DIRECTORY "${target_path}")
    set(target_path "${target_path}/${filename}")    
  endif()
  
  file(DOWNLOAD 
    "${uri_string}" "${target_path}" 
    STATUS status 
   # LOG log
    ${show_progress}
    TLS_VERIFY OFF 
    ${args})


  list_extract(status code message)
  if(NOT "${code}" STREQUAL 0)    
    error("failed to download: {message} (code {code})")
    rm("${target_path}")
    return()
  endif()

  return_ref(target_path)
endfunction()





  ## downloadsa the specified url and stores it in target file
  ## if specified
  ## --refresh causes the cache to be updated
  ## --readonly allows optimization if the result is not modified
  function(download_cached uri)
    set(args ${ARGN})
    list_extract_flag(args --refresh)
    ans(refresh)
    list_extract_flag(args --readonly)
    ans(readonly)
    
    cmakepp_config(cache_dir)
    ans(cache_dir)

    string(MD5 cache_key "${uri}")
    set(cached_path "${cache_dir}/download_cache/${cache_key}")
   
    if(EXISTS "${cached_path}" AND NOT refresh)
      if(readonly)
        glob("${cached_path}/**")
        ans(file_path)
        if(EXISTS "${file_path}")
          return_ref(file_path)
        endif()
        rm("${cached_path}")
      else()
        message(FATAL_ERROR "not supported")
      endif()
    endif()

    mkdir("${cached_path}")
    download("${uri}" "${cached_path}" ${args})
    ans(res)
    if(NOT res)
      rm("${cached_path}")
    endif()
    return_ref(res)
  endfunction()





## github_api()
## 
## 
function(github_api)
  set(github_api_token)
  if(NOT "$ENV{GITHUB_DEVEL_TOKEN_ID}_" STREQUAL "_" )
    set(github_api_token "?client_id=$ENV{GITHUB_DEVEL_TOKEN_ID}&client_secret=$ENV{GITHUB_DEVEL_TOKEN_SECRET}")
  endif()
  set(api_uri "https://api.github.com")
  define_http_resource(github_api "${api_uri}/:path${github_api_token}")

  github_api(${ARGN})
  return_ans()
endfunction()




    function(github_get_file user repo ref path)
        set(raw_uri "https://raw.githubusercontent.com/")
        set(path_uri "${raw_uri}/${user}/${repo}/${ref}/${path}" )
        http_get("${path_uri}" ${ARGN})
        return_ans()
    endfunction()






## github_remote_refs( <?ref type query>)-> {
##   ref_type: "branches"|"tags"|"commits"
##   ref: <name>
##   commit: <sha>
## }
##
## ref type query ::= "branches"|"tags"|"commits"|"*"
## returns the remote refs for the specified github repository
function(github_remote_refs user repo ref_query)
  set(args ${ARGN})
  list_pop_front(args)
  ans(ref_name_query)

  set(tags)
  set(branches)
  set(commits)
  set(refs)

  if(ref_query AND "${ref_query}" STREQUAL "commits" AND ref_name_query)
      github_api("repos/${user}/${repo}/commits/${ref_name_query}" --exit-code)
      ans(error)
      if(NOT error)
        set(ref ${ref_name_query})
        set(commit ${ref_name_query})
        set(ref_type "commits")
        map_capture_new(ref_type ref commit)
        ans_append(refs)
      endif()
  endif()

  if(ref_query AND "${ref_query}" STREQUAL "*" OR "${ref_query}" STREQUAL "tags")
    github_api("repos/${user}/${repo}/tags" --json --silent-fail)
    ans(tags)
    foreach(tag ${tags})
      assign(ref = tag.name)
      assign(commit = tag.commit.sha)
      set(ref_type "tags")
      map_capture_new(ref_type ref commit)
      ans_append(refs)
    endforeach()
  endif()
  if(ref_query AND "${ref_query}" STREQUAL "*" OR "${ref_query}" STREQUAL "branches")
    github_api("repos/${user}/${repo}/branches" --json --silent-fail)
    ans(branches)

    foreach(branch ${branches})  
      assign(ref = branch.name)
      assign(commit = branch.commit.sha)
      set(ref_type "branches")
      map_capture_new(ref_type ref commit)
      ans_append(refs)
    endforeach()

  endif()

  if(ref_name_query AND NOT "${ref_name_query}" STREQUAL "*")
    set(result)
    foreach(ref ${refs})
      map_tryget(${ref} ref)
      ans(ref_name)
      map_tryget(${ref} commit)
      ans(commit)
      if("${ref_name_query}" STREQUAL "${ref_name}" OR "${ref_name_query}" STREQUAL "${commit}")
        list(APPEND result ${ref})
      endif()
    endforeach()
    set(refs ${result})
  endif()
  return_ref(refs)
endfunction()





  
## github_repository(<user> <repo>)-> {
##  full_name:
##  default_branch: 
## }
##
##  returns a github repository object if the repo exists
function(github_repository user repo)
  github_api("repos/${user}/${repo}" --silent-fail)
  ans(res)
  if(NOT res)
    return()
  endif()

  json_extract_string_value("default_branch" "${res}")
  ans(default_branch)
  json_extract_string_value("full_name" "${res}")
  ans(full_name)

  map_capture_new(full_name default_branch)
  return_ans()


endfunction()




## github_repositories() -> {
##   full_name:
##   default_branch:
## }
##
## returns the list of repositories for the specified user
function(github_repository_list user)
  set(repositories)
    github_api("users/${user}/repos" --response)
    ans(res)
    assign(error = res.client_status)
    if(error)
      return()
    endif()
    assign(content = res.content)

    
    ## this is a quick way to get all full_name fields of the unparsed json
    ## parsing large json files would be much too slow
    json_extract_string_value(full_name "${content}")
    ans(full_names)
    json_extract_string_value(default_branch "${content}")
    ans(default_branches)

    set(repos)
    foreach(full_name ${full_names})
      list_pop_front(default_branches)
      ans(default_branch)
      map_capture_new(full_name default_branch)
      ans_append(repos)
    endforeach() 
    return_ref(repos)
endfunction()









## http_get(<~uri> <?content:<structured data>> [--progress] [--response] [--exit-code] )-> <http response>
##
##
## flags: 
##   --json         flag deserializes the content and returns it 
##   --show-progress     flag prints the progress of the download to the console
##   --response     flag
##   --exit-code  flag
##   --silent-fail  flag
##  
function(http_get uri)
  set(args ${ARGN})
  list_extract_flag(args --json)
  ans(return_json)
  list_extract_flag(args --show-progress)
  ans(show_progress)
  list_extract_flag(args --response)
  ans(return_response)
  list_extract_flag(args --exit-code)
  ans(return_error)
  list_extract_flag(args --silent-fail)
  ans(silent_fail)

  set(show_progress)
  if(show_progress)
    set(show_progress SHOW_PROGRESS)
  endif()
  
  path_temp()
  ans(target_path)

  list_pop_front(args)
  ans(content)

  obj("${content}")
  ans(content)

  uri("${uri}")
  ans(uri)

  uri_format("${uri}" "${content}")
  ans(uri)

  if(return_response)
    set(log LOG http_log)
  endif()

  event_emit(on_http_get "${uri}")
  ans(modified_uri)

  if(modified_uri)
    set(uri "${modified_uri}")
  endif()

  ## actual request - uses file DOWNLOAD which 
  ## uses cUrl internally 
  file(DOWNLOAD 
    "${uri}" 
    "${target_path}" 
    STATUS status 
    ${log}
    ${show_progress}
    TLS_VERIFY OFF 
    ${args}
  )

  # split status into client_status and client_message
  list_extract(status client_status client_message)

  ## return only error code if requested
  if(return_error)
    return_ref(client_status)
  endif()

  ## read content if client was executed correctly
  ## afterwards delete file
  if(NOT client_status)
    fread("${target_path}")
    ans(content)
  else()
    error("http_get failed for '{uri}': ${client_message}")
    if(NOT silent_fail AND NOT return_response)
      rm("${target_path}")
      if("$ENV{TRAVIS}")
        ## do not show the query if travis build because it could contain sensitive
        ## data
        uri_format("${uri}" --no-query)
        ans(uri)
      endif()
      message(FATAL_ERROR "http_get failed for '${uri}': ${client_message}")
    elseif(silent_fail AND NOT return_response)
      rm("${target_path}")
      return()
    endif()
  endif()
  rm("${target_path}")

  ## if the response is not to be returnd
  ## check if deserialization is wished and 
  ## and return content
  if(NOT return_response)
    if(return_json)
      json_deserialize("${content}")
      ans(content)
    endif()
    return_ref(content)
  endif()

  ## parse response and set further fields
  http_last_response_parse("${http_log}")
  ans(response)

  map_set(${response} content "${content}")
  map_set(${response} client_status "${client_status}")
  map_set(${response} client_message "${client_message}")
  map_set(${response} request_url "${uri}")

  string(LENGTH "${content}" content_length)
  map_set(${response} content_length "${content_length}")
  map_set(${response} http_log "${http_log}")

  return_ref(response)
endfunction()






function(http_headers_parse http_headers)
  http_regexes()
  string_encode_semicolon("${http_headers}")
  ans(http_headers)

  string(REGEX MATCHALL "${http_header_regex}" http_header_lines "${http_headers}")

  map_new()
  ans(result)
  foreach(header_line ${http_header_lines})
    string(REGEX REPLACE "${http_header_regex}" "\\1" header_key "${header_line}")
    string(REGEX REPLACE "${http_header_regex}" "\\2" header_value "${header_line}")
    string_decode_semicolon("${header_value}")
    ans(header_value)
    map_set(${result} "${header_key}" "${header_value}")
  endforeach()

  return_ref(result)
endfunction()






## returns a response object for the last response in the specified http_log
## http_log is returned by cmake's file(DOWNLOAD|PUT LOG) function
## layout
## {
##   http_version:
##   http_status_code:
##   http_reason_phrase:
##   http_headers:{}
##   http_request:{
##      http_version:	
##      http_request_url:	
##      http_method:
##      http_headers:{}	
##   }
## }
function(http_last_response_parse http_log)
	string_encode_semicolon("${http_log}")
	ans(http_log)
	http_regexes()
	
	string(REGEX MATCHALL "(${http_request_header_regex})" requests "${http_log}")
	string(REGEX MATCHALL "(${http_response_header_regex})" responses "${http_log}")

	list_pop_back(requests)
	ans(request)
	http_request_header_parse("${request}")
	ans(request)

	list_pop_back(responses)
	ans(response)

	http_response_header_parse("${response}")
	ans(response)
	map_set(${response} http_request "${request}")
	return_ref(response)
endfunction()




## http_put() -> 
##
## flags:
##   --response     						flag will return the http response object
##
##   --json											flag will deserialize the result data
##
##   --exit-code    						flag will return the http clients return code 
##															non-zero indicates an error
##   --show-progress 						flag causes a console message which indicates 
##															the progress of the operation
##
##   --raw           					 	flag witll cause input to be sent raw 
##															if flag is not specified the input is serialized
##															to json before sending
##
##   --file <file>							flag PUT the specified file instead of the input
##
##   --silent-fail						 	flag causes function to return nothing if it fails
##															(only usable if --response was not set)
##
##   --timeout <n>						 	value 
##
##   --inactivity-timeout <n>  	value 
## 
## events:
##   on_http_put(<uri> <content>)-> <uri?>:
##     event is called before put request is performed
##     user may cancel event and return a modified uri 
##     which is used to perform the request 
function(http_put uri)
	set(args ${ARGN})

	list_extract_flag(args --response)
	ans(return_response)

	list_extract_labelled_value(args --timeout)
	ans(timeout)
	
	list_extract_labelled_value(args --inactivity-timeout)
	ans(inactivity_timeout)

	list_extract_flag(args --show-progress)
	ans(show_progress)

	list_extract_flag(args --exit-code)
	ans(return_return_code)

	list_extract_flag(args --json)
	ans(return_json)

	list_extract_flag(args --raw)
	ans(put_raw)

	list_extract_labelled_value(args --file)
	ans(put_file)

	list_extract_flag(args --silent-fail)
	ans(silent_fail)

	path_temp()
	ans(temp_file)

	if(put_file)
		path_qualify(put_file)
		set(content_file "${put_file}")
		if(NOT EXISTS "${content_file}")
			error("http_put - file does not exists ${content_file}")
			message(FATAL_ERROR "http_put - file does not exists ${content_file}")
		endif()
	else()
		if(NOT put_raw)
			data("${args}")
			ans(content)
			json_write("${temp_file}" ${content})
			set(content_file "${temp_file}")
		else()
			fwrite("${temp_file}" "${args}")
			set(content_file "${temp_file}")
		endif()

	endif()

	## emit on_http_put event 
	## 
	event_emit(on_http_put ${uri} ${content})
	ans(modified_uri)
	if(modified_uri)
		set(uri "${modified_uri}")
	endif()

	## delegate cmake flags in correct format to file command
	if(show_progress)
		set(show_progress SHOW_PROGRESS)
	endif()
	if(NOT "${timeout}_" STREQUAL "_")
		set(timeout TIMEOUT "${timeout}")
	endif()
	if(NOT "${inactivity_timeout}_" STREQUAL "_")
		set(inactivity_timeout INACTIVITY_TIMEOUT "${inactivity_timeout}")
	endif()

	## upload a file (this actaully does a http put request)
	file(UPLOAD 
		"${content_file}" 
		"${uri}" 
		STATUS client_result 
		LOG http_log 
		${show_progress}
		${timeout}
		${inactivity_timeout}
	)
	## parse http client status
	list_extract(client_result client_status client_message)
	if(EXISTS "${temp_file}")
		rm("${temp_file}")
	endif()

	if(return_return_code)
		return_ref(client_status)
	endif()

	## parse response from log since it is not downloaded
	set(response_content)
	if("${http_log}" MATCHES  "Response:\n(.*)\n\nDebug:\n")
		set(response_content "${CMAKE_MATCH_1}")
	endif()
	
	if(NOT return_response AND client_status)
		error("http_put failed: ${client_message} - ${client_status}")
		if(NOT silent_fail)
			message(FATAL_ERROR "http_put failed: ${client_message} - ${client_status}")
		endif()
		return()
	endif()


	if(return_json)
		json_deserialize("${response_content}")
		ans(response_content)
	endif()

	if(NOT return_response)
		return_ref(response_content)
	endif()

	## parse rest of response
	http_last_response_parse("${http_log}")
	ans(response)

	map_set(${response} content "${response_content}")
	map_set(${response} client_status "${client_status}")
	map_set(${response} client_message "${client_message}")

	return_ref(response)
endfunction()







function(http_request_header_parse http_request)
  http_regexes()

  string_encode_semicolon("${http_request}")
  ans(http_request)

  string(REGEX REPLACE "${http_request_header_regex}" "\\1" http_request_line "${http_request}")
  string(REGEX REPLACE "${http_request_header_regex}" "\\5" http_request_headers "${http_request}")

  string(REGEX REPLACE "${http_request_line_regex}" "\\1" http_method "${http_request_line}")
  string(REGEX REPLACE "${http_request_line_regex}" "\\2" http_request_uri "${http_request_line}")
  string(REGEX REPLACE "${http_request_line_regex}" "\\3" http_version "${http_request_line}")


  
  http_headers_parse("${http_request_headers}")
  ans(http_headers)

  map_new()
  ans(result)

  map_set(${result} http_method "${http_method}")
  map_set(${result} http_request_uri "${http_request_uri}")
  map_set(${result} http_version "${http_version}")
  map_set(${result} http_headers ${http_headers})

  return_ref(result)
endfunction()






function(http_response_header_parse http_response)
  http_regexes()
  string_encode_semicolon("${http_response}")
  ans(http_response)

  string(REGEX REPLACE "${http_response_header_regex}" "\\1" response_line "${response}")
  string(REGEX REPLACE "${http_response_header_regex}" "\\5" response_headers "${response}")

  string(REGEX REPLACE "${http_response_line_regex}" "\\1" http_version "${response_line}" )
  string(REGEX REPLACE "${http_response_line_regex}" "\\2" http_status_code "${response_line}" )
  string(REGEX REPLACE "${http_response_line_regex}" "\\3" http_reason_phrase "${response_line}" )



  http_headers_parse("${response_headers}")
  ans(http_headers)


  map_new()
  ans(result)
  map_set(${result} "http_version" "${http_version}")
  map_set(${result} "http_status_code" "${http_status_code}")
  map_set(${result} "http_reason_phrase" "${http_reason_phrase}")
  map_set(${result} "http_headers" "${http_headers}")
  return_ref(result)

endfunction()

## include task_enqueue last



## this file should not have the extension .cmake 
## because it needs to be included manually and last
## adds a callable as a task which is to be invoked later
function(task_enqueue callable)  
  function_import("${callable}")
  ans(callback)
  map_new()
  ans(task)
  map_set("${task}" state "waiting")
  map_set("${task}" callback "${callback}")
  map_set("${task}" callable "${callable}")
  map_append(global task_queue ${task})

  return_ref(task)
  ## semicolon encode before string_encode_semicolon exists
  string(ASCII  31 us)
  string(REPLACE ";" "${us}" callable "${callable}")
  set_property(GLOBAL APPEND PROPERTY __initial_invoke_later_list "${callable}") 
  return()
endfunction()

# initial version of task_enqueue which is used before cmakepp is loaded
# ## create invoke later functions 
# function(task_enqueue callable)
#   ## semicolon encode before string_encode_semicolon exists
#   string(ASCII  31 us)
#   string(REPLACE ";" "${us}" callable "${callable}")
#   set_property(GLOBAL APPEND PROPERTY __initial_invoke_later_list "${callable}") 
#   return()
# endfunction()


## setup global variables to contain command_line_args
parse_command_line(command_line_args "${command_line_args}") # parses quoted command line args
map_set(global "command_line_args" ${command_line_args})
map_set(global "unused_command_line_args" ${command_line_args})
## todo... change this 
# setup cmakepp config
map()
	kv(base_dir
		LABELS --cmakepp-base-dir
		MIN 1 MAX 1
		DISPLAY_NAME "cmakepp installation dir"
		DEFAULT "${CMAKE_CURRENT_LIST_DIR}"
		)
  kv(keep_temp 
    LABELS --keep-tmp --keep-temp -kt 
    MIN 0 MAX 0 
    DESCRIPTION "does not delete temporary files after") 
  kv(temp_dir
  	LABELS --temp-dir
  	MIN 1 MAX 1
  	DESCRIPTION "the directory used for temporary files"
  	DEFAULT "${cmakepp_tmp_dir}/cutil/temp"
  	)
  kv(cache_dir
  	LABELS --cache-dir
  	MIN 1 MAX 1
  	DESCRIPTION "the directory used for caching data"
  	DEFAULT "${cmakepp_tmp_dir}/cutil/cache"
  	)
  kv(bin_dir
    LABELS --bin-dir
    MIN 1 MAX 1
    DEFAULT "${CMAKE_CURRENT_LIST_DIR}/bin"
    )
  kv(cmakepp_path
    LABELS --cmakepp-path
    MIN 1 MAX 1
    DEFAULT "${CMAKE_CURRENT_LIST_FILE}"
    )
end()
ans(cmakepp_config_definition)
cd("${CMAKE_SOURCE_DIR}")
# setup config_function for cmakepp
config_setup("cmakepp_config" ${cmakepp_config_definition})
## run all currently enqueued tasks
task_run_all()
## check if in script mode and script file is equal to this file
## then invoke either cli mode
cmake_entry_point()
ans(entry_point)
if("${CMAKE_CURRENT_LIST_FILE}" STREQUAL "${entry_point}")
  cmakepp_cli()
endif()
## variables expected by cmake's find_package method
set(CMAKEPP_FOUND true)
set(CMAKEPP_VERSION_MAJOR "0")
set(CMAKEPP_VERSION_MINOR "0")
set(CMAKEPP_VERSION_PATCH "0")
set(CMAKEPP_VERSION "${CMAKEPP_VERSION_MAJOR}.${CMAKEPP_VERSION_MINOR}.${CMAKEPP_VERSION_PATCH}")
set(CMAKEPP_BASE_DIR "${cmakepp_base_dir}")
set(CMAKEPP_BIN_DIR "${cmakepp_base_dir}/bin")
set(CMAKEPP_TMP_DIR "${cmakepp_tmp_dir}")
set(cmakepp_path "${CMAKE_CURRENT_LIST_FILE}")
set(CMAKEPP_PATH "${CMAKE_CURRENT_LIST_FILE}")
## setup file
set(ENV{CMAKEPP_PATH} "${CMAKE_CURRENT_LIST_FILE}")
