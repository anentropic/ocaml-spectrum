(** equivalent to [Format.fprintf] *)
val fprintf :
  Format.formatter -> ('a, Format.formatter, unit, unit) format4 -> 'a

(** equivalent to [Format.printf] *)
val printf : ('a, Format.formatter, unit, unit) format4 -> 'a

(** equivalent to [Format.eprintf] *)
val eprintf : ('a, Format.formatter, unit, unit) format4 -> 'a

(** substitute for [Format.sprintf], first arg will be updated with what would normally be return value from [sprintf] *)
val sprintf_into :
  string ref -> ('a, Format.formatter, unit, unit) format4 -> 'a
