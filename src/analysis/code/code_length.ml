(**************************************************************************)
(*                                                                        *)
(*                        OCamlPro Typerex                                *)
(*                                                                        *)
(*   Copyright OCamlPro 2011-2016. All rights reserved.                   *)
(*   This file is distributed under the terms of the GPL v3.0             *)
(*   (GNU General Public Licence version 3.0).                            *)
(*                                                                        *)
(*     Contact: <typerex@ocamlpro.com> (http://www.ocamlpro.com/)         *)
(*                                                                        *)
(*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       *)
(*  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES       *)
(*  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND              *)
(*  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS   *)
(*  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN    *)
(*  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN     *)
(*  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE      *)
(*  SOFTWARE.                                                             *)
(**************************************************************************)

open SimpleConfig (* for !! *)

(* We will register this linter to the Mascot plugin. *)
module Mascot = Plugin_mascot.PluginMascot

let default_value = 80

let details =
  Printf.sprintf
    "Checks long lines in your code. The default value is %d."
    default_value

module CodeLength = Mascot.MakeLint(struct
    let name = "Code Length"
    let short_name = "code_length"
    let details = details
  end)

(* Defining/Using option from configuration file / command line *)
let max_line_length = CodeLength.create_option
    "max_line_length"
    "Maximum line length"
    "Maximum line length"
    SimpleConfig.int_option
    default_value

type warning = LongLine of int

module Warnings = CodeLength.MakeWarnings(struct
    type t = warning

    let line_too_long loc args = CodeLength.new_warning
        loc
        1
        [ Warning.kind_code ]
        ~short_name:"long_line"
        ~msg:"This line is too long ('$line'): it should be at \
              most of size '$max'."
        ~args

    let report loc = function
      | LongLine len ->
        line_too_long loc
          [("line", string_of_int len);
           ("max", string_of_int !!max_line_length)]
  end)

let check_line lnum file line =
  let line_len = String.length line in
  if line_len > !!max_line_length then
    let pos = Lexing.({dummy_pos with pos_fname = file; pos_lnum = lnum}) in
    let loc = Location.({none with loc_start = pos}) in
    Warnings.report loc (LongLine line_len)

let check_file file =
  let ic = open_in file in
  let rec loop lnum ic =
    try
      check_line lnum file (input_line ic);
      loop (lnum + 1) ic
    with End_of_file -> () in
  loop 1 ic;
  close_in ic

(* Registering a main entry to the linter *)
module MainSRC = CodeLength.MakeInputML(struct
    let main source = check_file source
  end)
