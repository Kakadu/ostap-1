(*
 * Test009: simplest ocamlyard test.
 * Copyright (C) 2006
 * Dmitri Boulytchev, St.Petersburg State University
 *
 * This software is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License version 2, as published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU Library General Public License version 2 for more details
 * (enclosed in the file COPYING).
 *)

open Re_str
open Ostap
open Types

class lexer (s : string) =
  object (self : 'self)

    val ws    = regexp "[' ''\n''\t']+"
    val ident = regexp "[a-zA-Z]\([a-zA-Z0-9]\)*"
    val p = 0
    val s = s

    method private pos = p
    method private str = s
    method equal : 'self -> bool =
      fun s' -> (s = s' # str) && (p = s' # pos)

    method getIDENT : 'b . (String.t -> 'self -> ('self, 'b, Reason.t) result) -> ('self, 'b, Reason.t) result =
      fun k ->
        let p =
          if string_match ws s p
          then p + (String.length (matched_string s))
          else p
        in
        if string_match ident s p
        then
          let m = matched_string s in
          k m {< p = p + String.length m >}
        else
          emptyResult

    method look : 'b . String.t -> (String.t -> 'self -> ('self, 'b, Reason.t) result) -> ('self, 'b, Reason.t) result =
      fun x k ->
        let p =
          if string_match ws s p
          then p + (String.length (matched_string s))
          else p
        in
        if string_match (regexp (quote x)) s p
        then
          let m = matched_string s in
          k m {< p = p + String.length m >}
        else emptyResult

    method getEOF : 'b . (String.t -> 'self -> ('self, 'b, Reason.t) result) -> ('self, 'b, Reason.t) result =
      fun k ->
        let p =
          if string_match ws s p
          then p + (String.length (matched_string s))
          else p
        in
        if p = String.length s
        then k "EOF" {< p = p >}
        else emptyResult
  end

module X =
  struct
    let parse = ostap (",")
  end

class ['a] ppp =
  object (self)

    method list = Combinators.Mem.memoize (fun s k (elem:'a) -> let ostap (l[elem]: hd:elem tl:(- !(X.parse) elem)* {hd :: tl}) in Combinators.Mem.mapply l s k elem)
    method m = ostap (!(self#list)[ostap (IDENT)] -EOF)

  end

let _ =
  let p = new ppp in
  begin match Combinators.Mem.mapply p#m (new lexer "r,t , f , g ,     u, i ") (fun res s -> Parsed ((res, s), None)) with
  | Parsed ((str, _), _) ->
      Printf.printf "Parsed: %s\n" (List.fold_left (^) "" str)
  | _ -> Printf.printf "Failed.\n"
  end;
  begin match Combinators.Mem.mapply p#m (new lexer " abc; def ") (fun res s -> Parsed ((res, s), None)) with
  | Parsed ((str, _), _) ->
      Printf.printf "Parsed: %s\n" (List.fold_left (^) "" str)
  | _ -> Printf.printf "Failed.\n"
  end;
