open Parsetree

(*
  ocamlfind ppx_tools/dumpast -loc_keep -attrs_keep lib/spectrum_palette/example.ml
*)
let example = [
  {pstr_desc =
     Pstr_module
       {pmb_name =
          {txt = Some "Basic";
           loc =
             {loc_start =
                {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
                 pos_bol = 0; pos_cnum = 7};
              loc_end =
                {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
                 pos_bol = 0; pos_cnum = 12};
              loc_ghost = false}};
        pmb_expr =
          {pmod_desc =
             Pmod_constraint
               ({pmod_desc =
                   Pmod_structure
                     [{pstr_desc =
                         Pstr_type (Recursive,
                                    [{ptype_name =
                                        {txt = "t";
                                         loc =
                                           {loc_start =
                                              {pos_fname = "lib/spectrum_palette/example.ml";
                                               pos_lnum = 2; pos_bol = 34; pos_cnum = 41};
                                            loc_end =
                                              {pos_fname = "lib/spectrum_palette/example.ml";
                                               pos_lnum = 2; pos_bol = 34; pos_cnum = 42};
                                            loc_ghost = false}};
                                      ptype_params = []; ptype_cstrs = [];
                                      ptype_kind =
                                        Ptype_variant
                                          [{pcd_name =
                                              {txt = "BrightWhite";
                                               loc =
                                                 {loc_start =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 3; pos_bol = 45; pos_cnum = 51};
                                                  loc_end =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 3; pos_bol = 45; pos_cnum = 62};
                                                  loc_ghost = false}};
                                            pcd_args = Pcstr_tuple []; pcd_res = None;
                                            pcd_loc =
                                              {loc_start =
                                                 {pos_fname = "lib/spectrum_palette/example.ml";
                                                  pos_lnum = 3; pos_bol = 45; pos_cnum = 49};
                                               loc_end =
                                                 {pos_fname = "lib/spectrum_palette/example.ml";
                                                  pos_lnum = 3; pos_bol = 45; pos_cnum = 62};
                                               loc_ghost = false};
                                            pcd_attributes = []}];
                                      ptype_private = Public; ptype_manifest = None;
                                      ptype_attributes = [];
                                      ptype_loc =
                                        {loc_start =
                                           {pos_fname = "lib/spectrum_palette/example.ml";
                                            pos_lnum = 2; pos_bol = 34; pos_cnum = 36};
                                         loc_end =
                                           {pos_fname = "lib/spectrum_palette/example.ml";
                                            pos_lnum = 3; pos_bol = 45; pos_cnum = 62};
                                         loc_ghost = false}}]);
                       pstr_loc =
                         {loc_start =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 2; pos_bol = 34; pos_cnum = 36};
                          loc_end =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 3; pos_bol = 45; pos_cnum = 62};
                          loc_ghost = false}};
                      {pstr_desc =
                         Pstr_value (Nonrecursive,
                                     [{pvb_pat =
                                         {ppat_desc =
                                            Ppat_var
                                              {txt = "of_string";
                                               loc =
                                                 {loc_start =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 5; pos_bol = 64; pos_cnum = 70};
                                                  loc_end =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 5; pos_bol = 64; pos_cnum = 79};
                                                  loc_ghost = false}};
                                          ppat_loc =
                                            {loc_start =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 5; pos_bol = 64; pos_cnum = 70};
                                             loc_end =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 5; pos_bol = 64; pos_cnum = 79};
                                             loc_ghost = false};
                                          ppat_loc_stack = []; ppat_attributes = []};
                                       pvb_expr =
                                         {pexp_desc =
                                            Pexp_function
                                              [{pc_lhs =
                                                  {ppat_desc =
                                                     Ppat_constant
                                                       (Pconst_string ("bright-white",
                                                                       {loc_start =
                                                                          {pos_fname =
                                                                             "lib/spectrum_palette/example.ml";
                                                                           pos_lnum = 6; pos_bol = 91; pos_cnum = 98};
                                                                        loc_end =
                                                                          {pos_fname =
                                                                             "lib/spectrum_palette/example.ml";
                                                                           pos_lnum = 6; pos_bol = 91; pos_cnum = 110};
                                                                        loc_ghost = false},
                                                                       None));
                                                   ppat_loc =
                                                     {loc_start =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 6; pos_bol = 91; pos_cnum = 97};
                                                      loc_end =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 6; pos_bol = 91; pos_cnum = 111};
                                                      loc_ghost = false};
                                                   ppat_loc_stack = []; ppat_attributes = []};
                                                pc_guard = None;
                                                pc_rhs =
                                                  {pexp_desc =
                                                     Pexp_construct
                                                       ({txt = Lident "BrightWhite";
                                                         loc =
                                                           {loc_start =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 6; pos_bol = 91;
                                                               pos_cnum = 115};
                                                            loc_end =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 6; pos_bol = 91;
                                                               pos_cnum = 126};
                                                            loc_ghost = false}},
                                                        None);
                                                   pexp_loc =
                                                     {loc_start =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 6; pos_bol = 91; pos_cnum = 115};
                                                      loc_end =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 6; pos_bol = 91; pos_cnum = 126};
                                                      loc_ghost = false};
                                                   pexp_loc_stack = []; pexp_attributes = []}};
                                               {pc_lhs =
                                                  {ppat_desc =
                                                     Ppat_var
                                                       {txt = "name";
                                                        loc =
                                                          {loc_start =
                                                             {pos_fname =
                                                                "lib/spectrum_palette/example.ml";
                                                              pos_lnum = 7; pos_bol = 127;
                                                              pos_cnum = 133};
                                                           loc_end =
                                                             {pos_fname =
                                                                "lib/spectrum_palette/example.ml";
                                                              pos_lnum = 7; pos_bol = 127;
                                                              pos_cnum = 137};
                                                           loc_ghost = false}};
                                                   ppat_loc =
                                                     {loc_start =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 7; pos_bol = 127; pos_cnum = 133};
                                                      loc_end =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 7; pos_bol = 127; pos_cnum = 137};
                                                      loc_ghost = false};
                                                   ppat_loc_stack = []; ppat_attributes = []};
                                                pc_guard = None;
                                                pc_rhs =
                                                  {pexp_desc =
                                                     Pexp_apply
                                                       ({pexp_desc =
                                                           Pexp_ident
                                                             {txt = Lident "@@";
                                                              loc =
                                                                {loc_start =
                                                                   {pos_fname =
                                                                      "lib/spectrum_palette/example.ml";
                                                                    pos_lnum = 7; pos_bol = 127;
                                                                    pos_cnum = 147};
                                                                 loc_end =
                                                                   {pos_fname =
                                                                      "lib/spectrum_palette/example.ml";
                                                                    pos_lnum = 7; pos_bol = 127;
                                                                    pos_cnum = 149};
                                                                 loc_ghost = false}};
                                                         pexp_loc =
                                                           {loc_start =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 7; pos_bol = 127;
                                                               pos_cnum = 147};
                                                            loc_end =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 7; pos_bol = 127;
                                                               pos_cnum = 149};
                                                            loc_ghost = false};
                                                         pexp_loc_stack = []; pexp_attributes = []},
                                                        [(Nolabel,
                                                          {pexp_desc =
                                                             Pexp_ident
                                                               {txt = Lident "raise";
                                                                loc =
                                                                  {loc_start =
                                                                     {pos_fname =
                                                                        "lib/spectrum_palette/example.ml";
                                                                      pos_lnum = 7; pos_bol = 127;
                                                                      pos_cnum = 141};
                                                                   loc_end =
                                                                     {pos_fname =
                                                                        "lib/spectrum_palette/example.ml";
                                                                      pos_lnum = 7; pos_bol = 127;
                                                                      pos_cnum = 146};
                                                                   loc_ghost = false}};
                                                           pexp_loc =
                                                             {loc_start =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 7; pos_bol = 127;
                                                                 pos_cnum = 141};
                                                              loc_end =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 7; pos_bol = 127;
                                                                 pos_cnum = 146};
                                                              loc_ghost = false};
                                                           pexp_loc_stack = []; pexp_attributes = []});
                                                         (Nolabel,
                                                          {pexp_desc =
                                                             Pexp_construct
                                                               ({txt =
                                                                   Ldot (Lident "Palette",
                                                                         "InvalidColorName");
                                                                 loc =
                                                                   {loc_start =
                                                                      {pos_fname =
                                                                         "lib/spectrum_palette/example.ml";
                                                                       pos_lnum = 7; pos_bol = 127;
                                                                       pos_cnum = 150};
                                                                    loc_end =
                                                                      {pos_fname =
                                                                         "lib/spectrum_palette/example.ml";
                                                                       pos_lnum = 7; pos_bol = 127;
                                                                       pos_cnum = 174};
                                                                    loc_ghost = false}},
                                                                Some
                                                                  {pexp_desc =
                                                                     Pexp_ident
                                                                       {txt = Lident "name";
                                                                        loc =
                                                                          {loc_start =
                                                                             {pos_fname =
                                                                                "lib/spectrum_palette/example.ml";
                                                                              pos_lnum = 7; pos_bol = 127;
                                                                              pos_cnum = 175};
                                                                           loc_end =
                                                                             {pos_fname =
                                                                                "lib/spectrum_palette/example.ml";
                                                                              pos_lnum = 7; pos_bol = 127;
                                                                              pos_cnum = 179};
                                                                           loc_ghost = false}};
                                                                   pexp_loc =
                                                                     {loc_start =
                                                                        {pos_fname =
                                                                           "lib/spectrum_palette/example.ml";
                                                                         pos_lnum = 7; pos_bol = 127;
                                                                         pos_cnum = 175};
                                                                      loc_end =
                                                                        {pos_fname =
                                                                           "lib/spectrum_palette/example.ml";
                                                                         pos_lnum = 7; pos_bol = 127;
                                                                         pos_cnum = 179};
                                                                      loc_ghost = false};
                                                                   pexp_loc_stack = [];
                                                                   pexp_attributes = []});
                                                           pexp_loc =
                                                             {loc_start =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 7; pos_bol = 127;
                                                                 pos_cnum = 150};
                                                              loc_end =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 7; pos_bol = 127;
                                                                 pos_cnum = 179};
                                                              loc_ghost = false};
                                                           pexp_loc_stack = []; pexp_attributes = []})]);
                                                   pexp_loc =
                                                     {loc_start =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 7; pos_bol = 127; pos_cnum = 141};
                                                      loc_end =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 7; pos_bol = 127; pos_cnum = 179};
                                                      loc_ghost = false};
                                                   pexp_loc_stack = []; pexp_attributes = []}}];
                                          pexp_loc =
                                            {loc_start =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 5; pos_bol = 64; pos_cnum = 82};
                                             loc_end =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 7; pos_bol = 127; pos_cnum = 179};
                                             loc_ghost = false};
                                          pexp_loc_stack = []; pexp_attributes = []};
                                       pvb_attributes = [];
                                       pvb_loc =
                                         {loc_start =
                                            {pos_fname = "lib/spectrum_palette/example.ml";
                                             pos_lnum = 5; pos_bol = 64; pos_cnum = 66};
                                          loc_end =
                                            {pos_fname = "lib/spectrum_palette/example.ml";
                                             pos_lnum = 7; pos_bol = 127; pos_cnum = 179};
                                          loc_ghost = false}}]);
                       pstr_loc =
                         {loc_start =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 5; pos_bol = 64; pos_cnum = 66};
                          loc_end =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 7; pos_bol = 127; pos_cnum = 179};
                          loc_ghost = false}};
                      {pstr_desc =
                         Pstr_value (Nonrecursive,
                                     [{pvb_pat =
                                         {ppat_desc =
                                            Ppat_var
                                              {txt = "to_code";
                                               loc =
                                                 {loc_start =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 9; pos_bol = 185; pos_cnum = 191};
                                                  loc_end =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 9; pos_bol = 185; pos_cnum = 198};
                                                  loc_ghost = false}};
                                          ppat_loc =
                                            {loc_start =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 9; pos_bol = 185; pos_cnum = 191};
                                             loc_end =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 9; pos_bol = 185; pos_cnum = 198};
                                             loc_ghost = false};
                                          ppat_loc_stack = []; ppat_attributes = []};
                                       pvb_expr =
                                         {pexp_desc =
                                            Pexp_function
                                              [{pc_lhs =
                                                  {ppat_desc =
                                                     Ppat_construct
                                                       ({txt = Lident "BrightWhite";
                                                         loc =
                                                           {loc_start =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 10; pos_bol = 210;
                                                               pos_cnum = 216};
                                                            loc_end =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 10; pos_bol = 210;
                                                               pos_cnum = 227};
                                                            loc_ghost = false}},
                                                        None);
                                                   ppat_loc =
                                                     {loc_start =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 10; pos_bol = 210; pos_cnum = 216};
                                                      loc_end =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 10; pos_bol = 210; pos_cnum = 227};
                                                      loc_ghost = false};
                                                   ppat_loc_stack = []; ppat_attributes = []};
                                                pc_guard = None;
                                                pc_rhs =
                                                  {pexp_desc =
                                                     Pexp_constant (Pconst_integer ("97", None));
                                                   pexp_loc =
                                                     {loc_start =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 10; pos_bol = 210; pos_cnum = 231};
                                                      loc_end =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 10; pos_bol = 210; pos_cnum = 233};
                                                      loc_ghost = false};
                                                   pexp_loc_stack = []; pexp_attributes = []}}];
                                          pexp_loc =
                                            {loc_start =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 9; pos_bol = 185; pos_cnum = 201};
                                             loc_end =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 10; pos_bol = 210; pos_cnum = 233};
                                             loc_ghost = false};
                                          pexp_loc_stack = []; pexp_attributes = []};
                                       pvb_attributes = [];
                                       pvb_loc =
                                         {loc_start =
                                            {pos_fname = "lib/spectrum_palette/example.ml";
                                             pos_lnum = 9; pos_bol = 185; pos_cnum = 187};
                                          loc_end =
                                            {pos_fname = "lib/spectrum_palette/example.ml";
                                             pos_lnum = 10; pos_bol = 210; pos_cnum = 233};
                                          loc_ghost = false}}]);
                       pstr_loc =
                         {loc_start =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 9; pos_bol = 185; pos_cnum = 187};
                          loc_end =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 10; pos_bol = 210; pos_cnum = 233};
                          loc_ghost = false}};
                      {pstr_desc =
                         Pstr_value (Nonrecursive,
                                     [{pvb_pat =
                                         {ppat_desc =
                                            Ppat_var
                                              {txt = "to_color";
                                               loc =
                                                 {loc_start =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 12; pos_bol = 235; pos_cnum = 241};
                                                  loc_end =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 12; pos_bol = 235; pos_cnum = 249};
                                                  loc_ghost = false}};
                                          ppat_loc =
                                            {loc_start =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 12; pos_bol = 235; pos_cnum = 241};
                                             loc_end =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 12; pos_bol = 235; pos_cnum = 249};
                                             loc_ghost = false};
                                          ppat_loc_stack = []; ppat_attributes = []};
                                       pvb_expr =
                                         {pexp_desc =
                                            Pexp_function
                                              [{pc_lhs =
                                                  {ppat_desc =
                                                     Ppat_construct
                                                       ({txt = Lident "BrightWhite";
                                                         loc =
                                                           {loc_start =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 13; pos_bol = 261;
                                                               pos_cnum = 267};
                                                            loc_end =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 13; pos_bol = 261;
                                                               pos_cnum = 278};
                                                            loc_ghost = false}},
                                                        None);
                                                   ppat_loc =
                                                     {loc_start =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 13; pos_bol = 261; pos_cnum = 267};
                                                      loc_end =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 13; pos_bol = 261; pos_cnum = 278};
                                                      loc_ghost = false};
                                                   ppat_loc_stack = []; ppat_attributes = []};
                                                pc_guard = None;
                                                pc_rhs =
                                                  {pexp_desc =
                                                     Pexp_apply
                                                       ({pexp_desc =
                                                           Pexp_ident
                                                             {txt = Ldot (Lident "Color", "of_rgb");
                                                              loc =
                                                                {loc_start =
                                                                   {pos_fname =
                                                                      "lib/spectrum_palette/example.ml";
                                                                    pos_lnum = 13; pos_bol = 261;
                                                                    pos_cnum = 282};
                                                                 loc_end =
                                                                   {pos_fname =
                                                                      "lib/spectrum_palette/example.ml";
                                                                    pos_lnum = 13; pos_bol = 261;
                                                                    pos_cnum = 294};
                                                                 loc_ghost = false}};
                                                         pexp_loc =
                                                           {loc_start =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 13; pos_bol = 261;
                                                               pos_cnum = 282};
                                                            loc_end =
                                                              {pos_fname =
                                                                 "lib/spectrum_palette/example.ml";
                                                               pos_lnum = 13; pos_bol = 261;
                                                               pos_cnum = 294};
                                                            loc_ghost = false};
                                                         pexp_loc_stack = []; pexp_attributes = []},
                                                        [(Nolabel,
                                                          {pexp_desc =
                                                             Pexp_constant (Pconst_integer ("255", None));
                                                           pexp_loc =
                                                             {loc_start =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 13; pos_bol = 261;
                                                                 pos_cnum = 295};
                                                              loc_end =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 13; pos_bol = 261;
                                                                 pos_cnum = 298};
                                                              loc_ghost = false};
                                                           pexp_loc_stack = []; pexp_attributes = []});
                                                         (Nolabel,
                                                          {pexp_desc =
                                                             Pexp_constant (Pconst_integer ("255", None));
                                                           pexp_loc =
                                                             {loc_start =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 13; pos_bol = 261;
                                                                 pos_cnum = 299};
                                                              loc_end =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 13; pos_bol = 261;
                                                                 pos_cnum = 302};
                                                              loc_ghost = false};
                                                           pexp_loc_stack = []; pexp_attributes = []});
                                                         (Nolabel,
                                                          {pexp_desc =
                                                             Pexp_constant (Pconst_integer ("255", None));
                                                           pexp_loc =
                                                             {loc_start =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 13; pos_bol = 261;
                                                                 pos_cnum = 303};
                                                              loc_end =
                                                                {pos_fname =
                                                                   "lib/spectrum_palette/example.ml";
                                                                 pos_lnum = 13; pos_bol = 261;
                                                                 pos_cnum = 306};
                                                              loc_ghost = false};
                                                           pexp_loc_stack = []; pexp_attributes = []})]);
                                                   pexp_loc =
                                                     {loc_start =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 13; pos_bol = 261; pos_cnum = 282};
                                                      loc_end =
                                                        {pos_fname = "lib/spectrum_palette/example.ml";
                                                         pos_lnum = 13; pos_bol = 261; pos_cnum = 306};
                                                      loc_ghost = false};
                                                   pexp_loc_stack = []; pexp_attributes = []}}];
                                          pexp_loc =
                                            {loc_start =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 12; pos_bol = 235; pos_cnum = 252};
                                             loc_end =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 13; pos_bol = 261; pos_cnum = 306};
                                             loc_ghost = false};
                                          pexp_loc_stack = []; pexp_attributes = []};
                                       pvb_attributes = [];
                                       pvb_loc =
                                         {loc_start =
                                            {pos_fname = "lib/spectrum_palette/example.ml";
                                             pos_lnum = 12; pos_bol = 235; pos_cnum = 237};
                                          loc_end =
                                            {pos_fname = "lib/spectrum_palette/example.ml";
                                             pos_lnum = 13; pos_bol = 261; pos_cnum = 306};
                                          loc_ghost = false}}]);
                       pstr_loc =
                         {loc_start =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 12; pos_bol = 235; pos_cnum = 237};
                          loc_end =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 13; pos_bol = 261; pos_cnum = 306};
                          loc_ghost = false}};
                      {pstr_desc =
                         Pstr_value (Nonrecursive,
                                     [{pvb_pat =
                                         {ppat_desc =
                                            Ppat_var
                                              {txt = "color_list";
                                               loc =
                                                 {loc_start =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 15; pos_bol = 310; pos_cnum = 316};
                                                  loc_end =
                                                    {pos_fname = "lib/spectrum_palette/example.ml";
                                                     pos_lnum = 15; pos_bol = 310; pos_cnum = 326};
                                                  loc_ghost = false}};
                                          ppat_loc =
                                            {loc_start =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 15; pos_bol = 310; pos_cnum = 316};
                                             loc_end =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 15; pos_bol = 310; pos_cnum = 326};
                                             loc_ghost = false};
                                          ppat_loc_stack = []; ppat_attributes = []};
                                       pvb_expr =
                                         {pexp_desc =
                                            Pexp_construct
                                              ({txt = Lident "::";
                                                loc =
                                                  {loc_start =
                                                     {pos_fname = "lib/spectrum_palette/example.ml";
                                                      pos_lnum = 16; pos_bol = 331; pos_cnum = 335};
                                                   loc_end =
                                                     {pos_fname = "lib/spectrum_palette/example.ml";
                                                      pos_lnum = 17; pos_bol = 361; pos_cnum = 364};
                                                   loc_ghost = true}},
                                               Some
                                                 {pexp_desc =
                                                    Pexp_tuple
                                                      [{pexp_desc =
                                                          Pexp_apply
                                                            ({pexp_desc =
                                                                Pexp_ident
                                                                  {txt = Ldot (Lident "Color", "of_rgb");
                                                                   loc =
                                                                     {loc_start =
                                                                        {pos_fname =
                                                                           "lib/spectrum_palette/example.ml";
                                                                         pos_lnum = 16; pos_bol = 331;
                                                                         pos_cnum = 335};
                                                                      loc_end =
                                                                        {pos_fname =
                                                                           "lib/spectrum_palette/example.ml";
                                                                         pos_lnum = 16; pos_bol = 331;
                                                                         pos_cnum = 347};
                                                                      loc_ghost = false}};
                                                              pexp_loc =
                                                                {loc_start =
                                                                   {pos_fname =
                                                                      "lib/spectrum_palette/example.ml";
                                                                    pos_lnum = 16; pos_bol = 331;
                                                                    pos_cnum = 335};
                                                                 loc_end =
                                                                   {pos_fname =
                                                                      "lib/spectrum_palette/example.ml";
                                                                    pos_lnum = 16; pos_bol = 331;
                                                                    pos_cnum = 347};
                                                                 loc_ghost = false};
                                                              pexp_loc_stack = []; pexp_attributes = []},
                                                             [(Nolabel,
                                                               {pexp_desc =
                                                                  Pexp_constant
                                                                    (Pconst_integer ("255", None));
                                                                pexp_loc =
                                                                  {loc_start =
                                                                     {pos_fname =
                                                                        "lib/spectrum_palette/example.ml";
                                                                      pos_lnum = 16; pos_bol = 331;
                                                                      pos_cnum = 348};
                                                                   loc_end =
                                                                     {pos_fname =
                                                                        "lib/spectrum_palette/example.ml";
                                                                      pos_lnum = 16; pos_bol = 331;
                                                                      pos_cnum = 351};
                                                                   loc_ghost = false};
                                                                pexp_loc_stack = []; pexp_attributes = []});
                                                              (Nolabel,
                                                               {pexp_desc =
                                                                  Pexp_constant
                                                                    (Pconst_integer ("255", None));
                                                                pexp_loc =
                                                                  {loc_start =
                                                                     {pos_fname =
                                                                        "lib/spectrum_palette/example.ml";
                                                                      pos_lnum = 16; pos_bol = 331;
                                                                      pos_cnum = 352};
                                                                   loc_end =
                                                                     {pos_fname =
                                                                        "lib/spectrum_palette/example.ml";
                                                                      pos_lnum = 16; pos_bol = 331;
                                                                      pos_cnum = 355};
                                                                   loc_ghost = false};
                                                                pexp_loc_stack = []; pexp_attributes = []});
                                                              (Nolabel,
                                                               {pexp_desc =
                                                                  Pexp_constant
                                                                    (Pconst_integer ("255", None));
                                                                pexp_loc =
                                                                  {loc_start =
                                                                     {pos_fname =
                                                                        "lib/spectrum_palette/example.ml";
                                                                      pos_lnum = 16; pos_bol = 331;
                                                                      pos_cnum = 356};
                                                                   loc_end =
                                                                     {pos_fname =
                                                                        "lib/spectrum_palette/example.ml";
                                                                      pos_lnum = 16; pos_bol = 331;
                                                                      pos_cnum = 359};
                                                                   loc_ghost = false};
                                                                pexp_loc_stack = []; pexp_attributes = []})]);
                                                        pexp_loc =
                                                          {loc_start =
                                                             {pos_fname =
                                                                "lib/spectrum_palette/example.ml";
                                                              pos_lnum = 16; pos_bol = 331;
                                                              pos_cnum = 335};
                                                           loc_end =
                                                             {pos_fname =
                                                                "lib/spectrum_palette/example.ml";
                                                              pos_lnum = 16; pos_bol = 331;
                                                              pos_cnum = 359};
                                                           loc_ghost = false};
                                                        pexp_loc_stack = []; pexp_attributes = []};
                                                       {pexp_desc =
                                                          Pexp_construct
                                                            ({txt = Lident "[]";
                                                              loc =
                                                                {loc_start =
                                                                   {pos_fname =
                                                                      "lib/spectrum_palette/example.ml";
                                                                    pos_lnum = 17; pos_bol = 361;
                                                                    pos_cnum = 363};
                                                                 loc_end =
                                                                   {pos_fname =
                                                                      "lib/spectrum_palette/example.ml";
                                                                    pos_lnum = 17; pos_bol = 361;
                                                                    pos_cnum = 364};
                                                                 loc_ghost = true}},
                                                             None);
                                                        pexp_loc =
                                                          {loc_start =
                                                             {pos_fname =
                                                                "lib/spectrum_palette/example.ml";
                                                              pos_lnum = 17; pos_bol = 361;
                                                              pos_cnum = 363};
                                                           loc_end =
                                                             {pos_fname =
                                                                "lib/spectrum_palette/example.ml";
                                                              pos_lnum = 17; pos_bol = 361;
                                                              pos_cnum = 364};
                                                           loc_ghost = true};
                                                        pexp_loc_stack = []; pexp_attributes = []}];
                                                  pexp_loc =
                                                    {loc_start =
                                                       {pos_fname = "lib/spectrum_palette/example.ml";
                                                        pos_lnum = 16; pos_bol = 331; pos_cnum = 335};
                                                     loc_end =
                                                       {pos_fname = "lib/spectrum_palette/example.ml";
                                                        pos_lnum = 17; pos_bol = 361; pos_cnum = 364};
                                                     loc_ghost = true};
                                                  pexp_loc_stack = []; pexp_attributes = []});
                                          pexp_loc =
                                            {loc_start =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 15; pos_bol = 310; pos_cnum = 329};
                                             loc_end =
                                               {pos_fname = "lib/spectrum_palette/example.ml";
                                                pos_lnum = 17; pos_bol = 361; pos_cnum = 364};
                                             loc_ghost = false};
                                          pexp_loc_stack = []; pexp_attributes = []};
                                       pvb_attributes = [];
                                       pvb_loc =
                                         {loc_start =
                                            {pos_fname = "lib/spectrum_palette/example.ml";
                                             pos_lnum = 15; pos_bol = 310; pos_cnum = 312};
                                          loc_end =
                                            {pos_fname = "lib/spectrum_palette/example.ml";
                                             pos_lnum = 17; pos_bol = 361; pos_cnum = 364};
                                          loc_ghost = false}}]);
                       pstr_loc =
                         {loc_start =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 15; pos_bol = 310; pos_cnum = 312};
                          loc_end =
                            {pos_fname = "lib/spectrum_palette/example.ml";
                             pos_lnum = 17; pos_bol = 361; pos_cnum = 364};
                          loc_ghost = false}}];
                 pmod_loc =
                   {loc_start =
                      {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
                       pos_bol = 0; pos_cnum = 27};
                    loc_end =
                      {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 18;
                       pos_bol = 365; pos_cnum = 368};
                    loc_ghost = false};
                 pmod_attributes = []},
                {pmty_desc =
                   Pmty_ident
                     {txt = Ldot (Lident "Palette", "M");
                      loc =
                        {loc_start =
                           {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
                            pos_bol = 0; pos_cnum = 15};
                         loc_end =
                           {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
                            pos_bol = 0; pos_cnum = 24};
                         loc_ghost = false}};
                 pmty_loc =
                   {loc_start =
                      {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
                       pos_bol = 0; pos_cnum = 15};
                    loc_end =
                      {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
                       pos_bol = 0; pos_cnum = 24};
                    loc_ghost = false};
                 pmty_attributes = []});
           pmod_loc =
             {loc_start =
                {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
                 pos_bol = 0; pos_cnum = 13};
              loc_end =
                {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 18;
                 pos_bol = 365; pos_cnum = 368};
              loc_ghost = false};
           pmod_attributes = []};
        pmb_attributes = [];
        pmb_loc =
          {loc_start =
             {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
              pos_bol = 0; pos_cnum = 0};
           loc_end =
             {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 18;
              pos_bol = 365; pos_cnum = 368};
           loc_ghost = false}};
   pstr_loc =
     {loc_start =
        {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 1;
         pos_bol = 0; pos_cnum = 0};
      loc_end =
        {pos_fname = "lib/spectrum_palette/example.ml"; pos_lnum = 18;
         pos_bol = 365; pos_cnum = 368};
      loc_ghost = false}}
]

(*
  ocamlfind ppx_tools/dumpast lib/spectrum_palette/example.ml
*)
(* let example_stripped = [
   {pstr_desc =
     Pstr_module
       {pmb_name = {txt = Some "Basic"};
        pmb_expr =
          {pmod_desc =
             Pmod_constraint
               ({pmod_desc =
                   Pmod_structure
                     [{pstr_desc =
                         Pstr_type (Recursive,
                                    [{ptype_name = {txt = "t"}; ptype_params = [];
                                      ptype_cstrs = [];
                                      ptype_kind =
                                        Ptype_variant
                                          [{pcd_name = {txt = "BrightWhite"};
                                            pcd_args = Pcstr_tuple []; pcd_res = None}];
                                      ptype_private = Public; ptype_manifest = None}])};
                      {pstr_desc =
                         Pstr_value (Nonrecursive,
                                     [{pvb_pat =
                                         {ppat_desc = Ppat_var {txt = "of_string"};
                                          ppat_loc_stack = []};
                                       pvb_expr =
                                         {pexp_desc =
                                            Pexp_function
                                              [{pc_lhs =
                                                  {ppat_desc =
                                                     Ppat_constant
                                                       (Pconst_string ("bright-white", ...));
                                                   ppat_loc_stack = []};
                                                pc_guard = None;
                                                pc_rhs =
                                                  {pexp_desc =
                                                     Pexp_construct ({txt = Lident "BrightWhite"},
                                                                     None);
                                                   pexp_loc_stack = []}};
                                               {pc_lhs =
                                                  {ppat_desc = Ppat_var {txt = "name"};
                                                   ppat_loc_stack = []};
                                                pc_guard = None;
                                                pc_rhs =
                                                  {pexp_desc =
                                                     Pexp_apply
                                                       ({pexp_desc = Pexp_ident {txt = Lident "@@"};
                                                         pexp_loc_stack = []},
                                                        [(Nolabel,
                                                          {pexp_desc = Pexp_ident {txt = Lident "raise"};
                                                           pexp_loc_stack = []});
                                                         (Nolabel,
                                                          {pexp_desc =
                                                             Pexp_construct
                                                               ({txt =
                                                                   Ldot (Lident "Palette",
                                                                         "InvalidColorName")},
                                                                Some
                                                                  {pexp_desc =
                                                                     Pexp_ident {txt = Lident "name"};
                                                                   pexp_loc_stack = []});
                                                           pexp_loc_stack = []})]);
                                                   pexp_loc_stack = []}}];
                                          pexp_loc_stack = []}}])};
                      {pstr_desc =
                         Pstr_value (Nonrecursive,
                                     [{pvb_pat =
                                         {ppat_desc = Ppat_var {txt = "to_code"};
                                          ppat_loc_stack = []};
                                       pvb_expr =
                                         {pexp_desc =
                                            Pexp_function
                                              [{pc_lhs =
                                                  {ppat_desc =
                                                     Ppat_construct ({txt = Lident "BrightWhite"},
                                                                     None);
                                                   ppat_loc_stack = []};
                                                pc_guard = None;
                                                pc_rhs =
                                                  {pexp_desc =
                                                     Pexp_constant (Pconst_integer ("97", None));
                                                   pexp_loc_stack = []}}];
                                          pexp_loc_stack = []}}])};
                      {pstr_desc =
                         Pstr_value (Nonrecursive,
                                     [{pvb_pat =
                                         {ppat_desc = Ppat_var {txt = "to_color"};
                                          ppat_loc_stack = []};
                                       pvb_expr =
                                         {pexp_desc =
                                            Pexp_function
                                              [{pc_lhs =
                                                  {ppat_desc =
                                                     Ppat_construct ({txt = Lident "BrightWhite"},
                                                                     None);
                                                   ppat_loc_stack = []};
                                                pc_guard = None;
                                                pc_rhs =
                                                  {pexp_desc =
                                                     Pexp_apply
                                                       ({pexp_desc =
                                                           Pexp_ident
                                                             {txt = Ldot (Lident "Color", "of_rgb")};
                                                         pexp_loc_stack = []},
                                                        [(Nolabel,
                                                          {pexp_desc =
                                                             Pexp_constant (Pconst_integer ("255", None));
                                                           pexp_loc_stack = []});
                                                         (Nolabel,
                                                          {pexp_desc =
                                                             Pexp_constant (Pconst_integer ("255", None));
                                                           pexp_loc_stack = []});
                                                         (Nolabel,
                                                          {pexp_desc =
                                                             Pexp_constant (Pconst_integer ("255", None));
                                                           pexp_loc_stack = []})]);
                                                   pexp_loc_stack = []}}];
                                          pexp_loc_stack = []}}])};
                      {pstr_desc =
                         Pstr_value (Nonrecursive,
                                     [{pvb_pat =
                                         {ppat_desc = Ppat_var {txt = "color_list"};
                                          ppat_loc_stack = []};
                                       pvb_expr =
                                         {pexp_desc =
                                            Pexp_construct ({txt = Lident "::"},
                                                            Some
                                                              {pexp_desc =
                                                                 Pexp_tuple
                                                                   [{pexp_desc =
                                                                       Pexp_apply
                                                                         ({pexp_desc =
                                                                             Pexp_ident
                                                                               {txt = Ldot (Lident "Color", "of_rgb")};
                                                                           pexp_loc_stack = []},
                                                                          [(Nolabel,
                                                                            {pexp_desc =
                                                                               Pexp_constant
                                                                                 (Pconst_integer ("255", None));
                                                                             pexp_loc_stack = []});
                                                                           (Nolabel,
                                                                            {pexp_desc =
                                                                               Pexp_constant
                                                                                 (Pconst_integer ("255", None));
                                                                             pexp_loc_stack = []});
                                                                           (Nolabel,
                                                                            {pexp_desc =
                                                                               Pexp_constant
                                                                                 (Pconst_integer ("255", None));
                                                                             pexp_loc_stack = []})]);
                                                                     pexp_loc_stack = []};
                                                                    {pexp_desc =
                                                                       Pexp_construct ({txt = Lident "[]"}, None);
                                                                     pexp_loc_stack = []}];
                                                               pexp_loc_stack = []});
                                          pexp_loc_stack = []}}])}]},
                {pmty_desc = Pmty_ident {txt = Ldot (Lident "Palette", "M")}})}}}
   ] *)
