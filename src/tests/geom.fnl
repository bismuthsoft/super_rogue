(local geom (require :geom))
(local lu (require :lib.luaunit))

(local TestGeom {})
(fn TestGeom.test_vec_eq []
  (lu.assertTrue (geom.vec-eq [0 0] [(geom.points->line [0 0] [1 0])]))
  (lu.assertTrue (geom.vec-eq [0 1] [(geom.points->line [0 1] [1 1])]))
  (lu.assertTrue (geom.vec-eq [1 1] [(geom.points->line [0 1] [1 2])]))
  (lu.assertTrue (geom.vec-eq [1 2] [1 2]))
  (lu.assertTrue (geom.vec-eq [1 2] [1 2.00000000001]))
  (lu.assertFalse (geom.vec-eq [1 2] [1 1])))

(fn TestGeom.test_line_intersection []
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [0 0] [[0 0] [3 3]]))
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [1.5 1.5] [[0 0] [3 3]]))
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [-1.5 -1.5] [[0 0] [-3 -3]]))
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [3 3] [[0 0] [3 3]]))
  (lu.assertEvalToFalse (geom.point-lineseg-intersection [1 2] [[1 -1] [1 1]])) ; vertical (out of range)
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [0 0.5] [[0 0] [0 1]])) ; vertical (in range)
  (lu.assertEvalToFalse (geom.point-lineseg-intersection [3 4] [[0 0] [3 3]]))
  (lu.assertEvalToTrue (geom.vec-eq [0 0] [(geom.line-line-intersection [0 0] [1 0])]))
  (lu.assertEvalToTrue (geom.vec-eq [0 1] [(geom.line-line-intersection [-1 1] [1 1])])))

(fn TestGeom.test_line_intersection_parallel []
  (lu.assertEvalToFalse (geom.line-line-intersection [0 0] [0 1]))
  (lu.assertEvalToFalse (geom.lineseg-lineseg-intersection [[0 0] [1 0]] [[1 1] [2 1]]))
  (lu.assertEvalToFalse (geom.lineseg-lineseg-intersection [[1 -1] [1 1]] [[0 2] [geom.FAR 2]])))

(fn TestGeom.test_line_intersection_extra []
  (lu.assertEvalToTrue (geom.vec-eq [0 0] [(geom.lineseg-lineseg-intersection ;; standard
                               [[-1 -1] [1 1]]
                               [[1 -1] [-1 1]])]))
  (lu.assertEvalToTrue (geom.lineseg-lineseg-intersection [[250 600] [250 40]] [[100 350] [300 350]])) ;; this case seems problematic
  (lu.assertTrue (geom.vec-eq [0 1] [(geom.lineseg-lineseg-intersection ;; vertical
                               [[0 0] [0 2]]
                               [[-1 1] [1 1]])])))

;; basic tests
(fn TestGeom.test_line_at_x []
  ;; vertical, expect error
  (lu.assertError (lambda []
                    (geom.vec-eq [0 0]
                                 [(geom.line-at-x [(/ 1 0) 0] [1 0])]))))

(set _G.TestGeom TestGeom)
TestGeom
