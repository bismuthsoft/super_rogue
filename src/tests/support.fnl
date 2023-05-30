(macro deftest [name lu testcase ...]
  '(do
     (local lu (require :lib.luaunit))
     (local Test# {})
     (fn Test#.)))
