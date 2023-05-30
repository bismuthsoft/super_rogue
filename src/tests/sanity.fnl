(local lu (require :lib.luaunit))

(local TestSanity {})
(fn TestSanity.test1_simple []
  (lu.assertEquals 1 1))

(set _G.TestSanity TestSanity)
TestSanity
