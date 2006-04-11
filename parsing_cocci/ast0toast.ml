(* Arities matter for the minus slice, but not for the plus slice. *)

(* + only allowed on code in a nest (in_nest = true).  ? only allowed on
rule_elems, and on subterms if the context is ? also. *)

module Ast0 = Ast0_cocci
module Ast = Ast_cocci

(* --------------------------------------------------------------------- *)

let get_option fn = function
    None -> None
  | Some x -> Some (fn x)

(* --------------------------------------------------------------------- *)
(* --------------------------------------------------------------------- *)
(* Mcode *)

let mcode(term,_,mcodekind) = (term,mcodekind)

(* --------------------------------------------------------------------- *)
(* Dots *)

let dots fn = function
    Ast0.DOTS(x) -> Ast.DOTS(List.map fn x)
  | Ast0.CIRCLES(x) -> Ast.CIRCLES(List.map fn x)
  | Ast0.STARS(x) -> Ast.STARS(List.map fn x)

let only_dots l =
  not (List.exists
	(function Ast.Circles(_,_) | Ast.Stars(_,_) -> true | _ -> false) l)

let only_circles l =
  not (List.exists
	(function Ast.Dots(_,_) | Ast.Stars(_,_) -> true | _ -> false) l)

let only_stars l =
  not (List.exists
	(function Ast.Dots(_,_) | Ast.Circles(_,_) -> true | _ -> false) l)


let top_dots l =
  if List.exists (function Ast.Circles(_) -> true | _ -> false) l
  then
    if only_circles l
    then Ast.CIRCLES(l)
    else failwith "inconsistent dots usage"
  else if List.exists (function Ast.Stars(_,_) -> true | _ -> false) l
  then
    if only_stars l
    then Ast.STARS(l)
    else failwith "inconsistent dots usage"
  else
    if only_dots l
    then Ast.DOTS(l)
    else failwith "inconsistent dots usage"

let concat_dots fn = function
    Ast0.DOTS(x) ->
      let l = List.concat(List.map fn x) in
      if only_dots l
      then Ast.DOTS(l)
      else failwith "inconsistent dots usage"
  | Ast0.CIRCLES(x) ->
      let l = List.concat(List.map fn x) in
      if only_circles l
      then Ast.CIRCLES(l)
      else failwith "inconsistent dots usage"
  | Ast0.STARS(x) ->
      let l = List.concat(List.map fn x) in
      if only_stars l
      then Ast.STARS(l)
      else failwith "inconsistent dots usage"

let flat_concat_dots fn = function
    Ast0.DOTS(x) -> List.concat(List.map fn x)
  | Ast0.CIRCLES(x) -> List.concat(List.map fn x)
  | Ast0.STARS(x) -> List.concat(List.map fn x)

(* --------------------------------------------------------------------- *)
(* Identifier *)


let rec ident = function
    Ast0.Id(name) -> Ast.Id(mcode name)
  | Ast0.MetaId(name) -> Ast.MetaId(mcode name)
  | Ast0.MetaFunc(name) -> Ast.MetaFunc(mcode name)
  | Ast0.MetaLocalFunc(name) -> Ast.MetaLocalFunc(mcode name)
  | Ast0.OptIdent(id) -> Ast.OptIdent(ident id)
  | Ast0.UniqueIdent(id) -> Ast.UniqueIdent(ident id)
  | Ast0.MultiIdent(id) -> Ast.MultiIdent(ident id)

(* --------------------------------------------------------------------- *)
(* Expression *)

let rec expression = function
    Ast0.Ident(id) -> Ast.Ident(ident id)
  | Ast0.Constant(const) ->
      Ast.Constant(mcode const)
  | Ast0.FunCall(fn,lp,args,rp) ->
      let fn = expression fn in
      let lp = mcode lp in
      let args = dots expression args in
      let rp = mcode rp in
      Ast.FunCall(fn,lp,args,rp)
  | Ast0.Assignment(left,op,right) ->
      Ast.Assignment(expression left,mcode op,expression right)
  | Ast0.CondExpr(exp1,why,exp2,colon,exp3) ->
      let exp1 = expression exp1 in
      let why = mcode why in
      let exp2 = get_option expression exp2 in
      let colon = mcode colon in
      let exp3 = expression exp3 in
      Ast.CondExpr(exp1,why,exp2,colon,exp3)
  | Ast0.Postfix(exp,op) ->
      Ast.Postfix(expression exp,mcode op)
  | Ast0.Infix(exp,op) ->
      Ast.Infix(expression exp,mcode op)
  | Ast0.Unary(exp,op) ->
      Ast.Unary(expression exp,mcode op)
  | Ast0.Binary(left,op,right) ->
      Ast.Binary(expression left,mcode op,expression right)
  | Ast0.Paren(lp,exp,rp) ->
      Ast.Paren(mcode lp,expression exp,mcode rp)
  | Ast0.ArrayAccess(exp1,lb,exp2,rb) ->
      Ast.ArrayAccess(expression exp1,mcode lb,expression exp2,mcode rb)
  | Ast0.RecordAccess(exp,pt,field) ->
      Ast.RecordAccess(expression exp,mcode pt,ident field)
  | Ast0.RecordPtAccess(exp,ar,field) ->
      Ast.RecordPtAccess(expression exp,mcode ar,ident field)
  | Ast0.Cast(lp,ty,rp,exp) ->
      Ast.Cast(mcode lp,typeC ty,mcode rp,expression exp)
  | Ast0.MetaConst(name,ty)  ->
      let name = mcode name in
      let ty = get_option (List.map typeC) ty in
      Ast.MetaConst(name,ty)
  | Ast0.MetaErr(name)  -> Ast.MetaErr(mcode name)
  | Ast0.MetaExpr(name,ty)  ->
      let name = mcode name in
      let ty = get_option (List.map typeC) ty in
      Ast.MetaExpr(name,ty)
  | Ast0.MetaExprList(name) -> Ast.MetaExprList(mcode name)
  | Ast0.EComma(cm)         -> Ast.EComma(mcode cm)
  | Ast0.DisjExpr(exps)     -> Ast.DisjExpr(List.map expression exps)
  | Ast0.NestExpr(exp_dots) -> Ast.NestExpr(dots expression exp_dots)
  | Ast0.Edots(dots,whencode) ->
      let dots = mcode dots in
      let whencode = get_option expression whencode in
      Ast.Edots(dots,whencode)
  | Ast0.Ecircles(dots,whencode) ->
      let dots = mcode dots in
      let whencode = get_option expression whencode in
      Ast.Ecircles(dots,whencode)
  | Ast0.Estars(dots,whencode) ->
      let dots = mcode dots in
      let whencode = get_option expression whencode in
      Ast.Estars(dots,whencode)
  | Ast0.OptExp(exp) -> Ast.OptExp(expression exp)
  | Ast0.UniqueExp(exp) -> Ast.UniqueExp(expression exp)
  | Ast0.MultiExp(exp) -> Ast.MultiExp(expression exp)

(* --------------------------------------------------------------------- *)
(* Types *)

and typeC = function
    Ast0.BaseType(ty,Some sign) -> Ast.BaseType(mcode ty,Some (mcode sign))
  | Ast0.BaseType(ty,None) -> Ast.BaseType(mcode ty,None)
  | Ast0.Pointer(ty,star) -> Ast.Pointer(typeC ty,mcode star)
  | Ast0.Array(ty,lb,size,rb) ->
      Ast.Array(typeC ty,mcode lb,get_option expression size,mcode rb)
  | Ast0.StructUnionName(name,kind) ->
      Ast.StructUnionName(mcode name,mcode kind)
  | Ast0.TypeName(name) -> Ast.TypeName(mcode name)
  | Ast0.MetaType(name) -> Ast.MetaType(mcode name)
  | Ast0.OptType(ty) -> Ast.OptType(typeC ty)
  | Ast0.UniqueType(ty) -> Ast.UniqueType(typeC ty)
  | Ast0.MultiType(ty) -> Ast.MultiType(typeC ty)

(* --------------------------------------------------------------------- *)
(* Variable declaration *)
(* Even if the Cocci program specifies a list of declarations, they are
   split out into multiple declarations of a single variable each. *)

let rec declaration = function
    Ast0.Init(ty,id,eq,exp,sem) ->
      let ty = typeC ty in
      let id = ident id in
      let eq = mcode eq in
      let exp = expression exp in
      let sem = mcode sem in
      Ast.Init(ty,id,eq,exp,sem)
  | Ast0.UnInit(ty,id,sem) -> Ast.UnInit(typeC ty,ident id,mcode sem)
  | Ast0.OptDecl(decl) -> Ast.OptDecl(declaration decl)
  | Ast0.UniqueDecl(decl) -> Ast.UniqueDecl(declaration decl)
  | Ast0.MultiDecl(decl) -> Ast.MultiDecl(declaration decl)

(* --------------------------------------------------------------------- *)
(* Parameter *)

let rec parameterTypeDef  = function
    Ast0.VoidParam(ty) -> Ast.VoidParam(typeC ty)
  | Ast0.Param(id,None,ty) -> Ast.Param(ident id,None,typeC ty)
  | Ast0.Param(id,Some vs,ty) -> Ast.Param(ident id,Some (mcode vs),typeC ty)
  | Ast0.MetaParam(name) -> Ast.MetaParam(mcode name)
  | Ast0.MetaParamList(name) -> Ast.MetaParamList(mcode name)
  | Ast0.PComma(cm) -> Ast.PComma(mcode cm)
  | Ast0.Pdots(dots) -> Ast.Pdots(mcode dots)
  | Ast0.Pcircles(dots) -> Ast.Pcircles(mcode dots)
  | Ast0.OptParam(param) -> Ast.OptParam(parameterTypeDef param)
  | Ast0.UniqueParam(param) -> Ast.UniqueParam(parameterTypeDef param)

let parameter_list = dots parameterTypeDef

(* --------------------------------------------------------------------- *)
(* Top-level code *)

let rec statement = function
    Ast0.Decl(decl) -> [Ast.Decl(declaration decl)]
  | Ast0.Seq(lbrace,body,rbrace) -> 
      let lbrace = mcode lbrace in
      let body = flat_concat_dots statement body in
      let rbrace = mcode rbrace in
      Ast.SeqStart(lbrace)::body@[Ast.SeqEnd(rbrace)]
  | Ast0.ExprStatement(exp,sem) ->
      [Ast.ExprStatement(expression exp,mcode sem)]
  | Ast0.IfThen(iff,lp,exp,rp,branch) ->
      Ast.IfHeader(mcode iff,mcode lp,expression exp,mcode rp)
      :: statement branch
  | Ast0.IfThenElse(iff,lp,exp,rp,branch1,els,branch2) ->
      Ast.IfHeader(mcode iff,mcode lp,expression exp,mcode rp)
      :: statement branch1 @ Ast.Else(mcode els) :: statement branch2
  | Ast0.While(wh,lp,exp,rp,body) ->
      Ast.WhileHeader(mcode wh,mcode lp,expression exp,mcode rp)
      :: statement body
  | Ast0.Do(d,body,wh,lp,exp,rp,sem) ->
      Ast.Do(mcode d) :: statement body @
      [Ast.WhileTail(mcode wh,mcode lp,expression exp,mcode rp,mcode sem)]
  | Ast0.For(fr,lp,exp1,sem1,exp2,sem2,exp3,rp,body) ->
      let fr = mcode fr in
      let lp = mcode lp in
      let exp1 = get_option expression exp1 in
      let sem1 = mcode sem1 in
      let exp2 = get_option expression exp2 in
      let sem2= mcode sem2 in
      let exp3 = get_option expression exp3 in
      let rp = mcode rp in
      let body = statement body in
      Ast.ForHeader(fr,lp,exp1,sem1,exp2,sem2,exp3,rp) :: body
  | Ast0.Return(ret,sem) -> [Ast.Return(mcode ret,mcode sem)]
  | Ast0.ReturnExpr(ret,exp,sem) ->
      [Ast.ReturnExpr(mcode ret,expression exp,mcode sem)]
  | Ast0.MetaStmt(name) -> [Ast.MetaStmt(mcode name)]
  | Ast0.MetaStmtList(name) -> [Ast.MetaStmtList(mcode name)]
  | Ast0.Exp(exp) -> [Ast.Exp(expression exp)]
  | Ast0.Disj(rule_elem_dots_list) ->
      [Ast.Disj(List.map (function x -> concat_dots statement x)
		  rule_elem_dots_list)]
  | Ast0.Nest(rule_elem_dots) ->
      [Ast.Nest(concat_dots statement rule_elem_dots)]
  | Ast0.Dots(dots,whencode)    ->
      let dots = mcode dots in
      let whencode = get_option (concat_dots statement) whencode in
      [Ast.Dots(dots,whencode)]
  | Ast0.Circles(dots,whencode) ->
      let dots = mcode dots in
      let whencode = get_option (concat_dots statement) whencode in
      [Ast.Circles(dots,whencode)]
  | Ast0.Stars(dots,whencode)   ->
      let dots = mcode dots in
      let whencode = get_option (concat_dots statement) whencode in
      [Ast.Stars(dots,whencode)]
  | Ast0.FunDecl(stg,name,lp,params,rp,lbrace,body,rbrace) ->
      let stg = get_option mcode stg in
      let name = ident name in
      let lp = mcode lp in
      let params = parameter_list params in
      let rp = mcode rp in
      let lbrace = mcode lbrace in
      let body = flat_concat_dots statement body in
      let rbrace = mcode rbrace in
      Ast.FunDecl(stg,name,lp,params,rp) :: Ast.SeqStart(lbrace) :: body @
      [Ast.SeqEnd(rbrace)]
  | Ast0.OptStm(stm) -> [Ast.OptRuleElem(statement stm)]
  | Ast0.UniqueStm(stm) -> [Ast.UniqueRuleElem(statement stm)]
  | Ast0.MultiStm(stm) -> [Ast.MultiRuleElem(statement stm)]
	
(* --------------------------------------------------------------------- *)
(* Function declaration *)
(* Haven't thought much about arity here... *)

let top_level = function
    Ast0.DECL(decl) -> Ast.DECL(declaration decl)
  | Ast0.INCLUDE(inc,s) -> Ast.INCLUDE(mcode inc,mcode s)
  | Ast0.FILEINFO(old_file,new_file) ->
      Ast.FILEINFO(mcode old_file,mcode new_file)
  | Ast0.FUNCTION(stmt) ->
      Ast.FUNCTION(top_dots(statement stmt))
  | Ast0.CODE(rule_elem_dots) ->
      Ast.CODE(concat_dots statement rule_elem_dots)
  | Ast0.ERRORWORDS(exps) ->
      Ast.ERRORWORDS(List.map expression exps)
  | Ast0.OTHER(_) -> failwith "eliminated by top_level"

(* --------------------------------------------------------------------- *)
(* Entry points *)

let ast0toast = List.map top_level
