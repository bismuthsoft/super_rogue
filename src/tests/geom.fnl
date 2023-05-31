(local geom (require :geom))
(local lu (require :lib.luaunit))

(local TestGeom {})

(fn TestGeom.test_is-infinite []
  (lu.assertTrue (geom.infinite? (/ 1 0)))
  (lu.assertTrue (geom.infinite? (/ -1 0)))
  (lu.assertTrue (geom.infinite? geom.FAR))
  (lu.assertTrue (geom.infinite? (- geom.FAR))))

(fn TestGeom.test_eq []
  (lu.assertTrue (geom.approx-eq 1 (- 1 (^ 2 -52))))
  (lu.assertTrue (geom.approx-eq 1 (+ 1 (^ 2 -52))))
  (lu.assertEquals [1 2] [1 2])
  (lu.assertTrue (geom.vec-eq [1 2] [1 (+ 2 (^ 2 -51))]))
  (lu.assertFalse (geom.vec-eq [1 2] [1 1])))

(fn TestGeom.test_simple_conversions []
  (lu.assertEquals [0 0] [(geom.points->line [0 0] [1 0])])
  (lu.assertEquals [0 1] [(geom.points->line [0 1] [1 1])])
  (lu.assertEquals [1 1] [(geom.points->line [0 1] [1 2])]))

(fn TestGeom.test_line_intersection []
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [0 0] [[0 0] [3 3]]))
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [1.5 1.5] [[0 0] [3 3]]))
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [-1.5 -1.5] [[0 0] [-3 -3]]))
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [3 3] [[0 0] [3 3]]))
  (lu.assertEvalToFalse (geom.point-lineseg-intersection [1 2] [[1 -1] [1 1]])) ; vertical (out of range)
  (lu.assertEvalToTrue (geom.point-lineseg-intersection [0 0.5] [[0 0] [0 1]])) ; vertical (in range)
  (lu.assertEvalToFalse (geom.point-lineseg-intersection [3 4] [[0 0] [3 3]]))
  (lu.assertEquals [(geom.line-line-intersection [0 0] [1 0])] [0 0])
  (lu.assertEquals [(geom.line-line-intersection [-1 1] [1 1])] [0 1])
  (lu.assertEquals [(geom.lineseg-lineseg-intersection
                      [[-1 -1] [1 1]]
                      [[1 -1] [-1 1]])]
                   [0 0])
  (lu.assertEvalToTrue (geom.lineseg-lineseg-intersection [[250 600] [250 40]] [[100 350] [300 350]])) ;; this case seems problematic
  (lu.assertEquals [(geom.lineseg-lineseg-intersection ;; vertical
                      [[0 0] [0 2]]
                      [[-1 1] [1 1]])] [0 1])
  (lu.assertEvalToTrue (geom.lineseg-lineseg-intersection
                         [[350 350] [0 350]]
                         [[250 559.80762113533] [250 40.192378864669]])))

(fn TestGeom.test_line_intersection_parallel []
  (lu.assertEvalToFalse (geom.line-line-intersection [0 0] [0 1]))
  (lu.assertEvalToFalse (geom.lineseg-lineseg-intersection [[0 0] [1 0]] [[1 1] [2 1]]))
  (lu.assertEvalToFalse (geom.lineseg-lineseg-intersection [[1 -1] [1 1]] [[0 2] [geom.FAR 2]])))

(fn TestGeom.test_line_at_x []
  ;; vertical, expect error
  (lu.assertError (lambda []
                    (geom.vec-eq [0 0]
                                 [(geom.line-at-x [(/ 1 0) 0] [1 0])]))))

(fn TestGeom.test_in_polygon_with_square []
  (local test-square [[-1 -1] [1 -1] [1 1] [-1 1]])
  (lu.assertFalse (geom.point-in-polygon? [0 2] test-square))
  (lu.assertTrue (geom.point-in-polygon? [0 0] test-square)) ; in square
  (lu.assertFalse (geom.point-in-polygon? [-2 0] test-square))) ; behind square

(fn TestGeom.test_in_polygon_with_triange []
  (local test-triangle
         [[250 559.80762113533]
          [250 40.192378864669]
          [700 300]])
  (lu.assertTrue (geom.point-in-polygon? [338.1735945625 288.93990457787] test-triangle))
  (lu.assertFalse (geom.point-in-polygon? [100 350] test-triangle))
  (lu.assertFalse (geom.point-in-polygon? [100 300] test-triangle)))

(fn TestGeom.test_lineseg_in_polygon []
  (local test-square [[-1 -1] [1 -1] [1 1] [-1 1]])
  (local test-triangle
         [[250 559.80762113533]
          [250 40.192378864669]
          [700 300]])
  (lu.assertEvalToFalse (geom.lineseg-polygon-intersection [[3 3] [2 2]] test-square))
  (lu.assertEquals [(geom.lineseg-polygon-intersection [[0 0] [0 2]] test-square)] [0 1])
  (lu.assertEquals [(geom.lineseg-polygon-intersection [[350 350] [0 350]] test-triangle)] [250 350]))

(fn TestGeom.circle-intersection []
  (lu.assertEvalToTrue (geom.point-circle-intersection [[0 0] [[0 0] 1]]))
  (lu.assertEvalToTrue (geom.point-circle-intersection [[0 0] [[1 1] 2]]))
  (lu.assertEvalToTrue (geom.point-circle-intersection [[5 5] [[0 0] 10]]))
  (lu.assertEvalToFalse (geom.point-circle-intersection [[5 5] [[0 0] 4]]))
  (lu.assertEvalToFalse (geom.point-circle-intersection [[0 0] [[5 5] 4]])))

(set _G.TestGeom TestGeom)
TestGeom
