;;; test-sqlite3.el --- Unit tests for sqlite3.el

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'ert)
(require 'sqlite3)

(ert-deftest sqlite3-new ()
  "Create sqlite3 instance"
  (let ((db (sqlite3-new)))
    (should db)))

(ert-deftest sqlite3-execute-batch ()
  "Execute SQL query"
  (let ((db (sqlite3-new)))
    (sqlite3-execute-batch db "CREATE TABLE foo(id integer primary key, name text);")
    (let ((got (sqlite3-execute-batch db "INSERT INTO foo(id, name) values(1, \"Tom\");")))
      (should (= got 1)))))

(ert-deftest sqlite3-execute-batch-placeholder ()
  "Execute SQL query with placeholder"
  (let ((db (sqlite3-new)))
    (sqlite3-execute-batch db "CREATE TABLE foo(id integer primary key, name text);")
    (let ((got (sqlite3-execute-batch db "INSERT INTO foo(name) values(?);" ["Bob"])))
      (should (= got 1)))))

(ert-deftest sqlite3-execute-exception ()
  "Execute invalid SQL query and raise exception."
  (let ((db (sqlite3-new)))
    (should-error (sqlite3-execute-batch db "FOO BAR BAZ;"))))

(ert-deftest sqlite3-execute-select-with-callback ()
  "Execute SELECT query with callback"
  (let ((db (sqlite3-new)))
    (sqlite3-execute-batch db "CREATE TABLE foo(id integer primary key, name text);")
    (sqlite3-execute-batch db "INSERT INTO foo(name) values(\"Tom\");")
    (sqlite3-execute-batch db "INSERT INTO foo(name) values(\"Bob\");")
    (sqlite3-execute-batch db "INSERT INTO foo(name) values(\"Chris\");")
    (let ((rows 0))
      (sqlite3-execute
       db
       "SELECT name FROM foo"
       (lambda (row fields)
         (cl-incf rows)
         (should (member (car row) '("Tom" "Bob" "Chris")))))
      (should (= rows 3)))

    (let ((rows 0))
      (sqlite3-execute
       db
       "SELECT name id, name FROM foo where id == 2"
       (lambda (row fields)
         (cl-incf rows)
         (should (string= (cl-second row) "Bob"))))
      (should (= rows 1)))))

(ert-deftest sqlite3-execute-select-with-resultset ()
  "Execute SELECT query with resultset"
  (let ((db (sqlite3-new)))
    (sqlite3-execute-batch db "CREATE TABLE foo(id integer primary key, name text);")
    (sqlite3-execute-batch db "INSERT INTO foo(name) values(\"Tom\");")
    (sqlite3-execute-batch db "INSERT INTO foo(name) values(\"Bob\");")
    (sqlite3-execute-batch db "INSERT INTO foo(name) values(\"Chris\");")
    (let ((resultset (sqlite3-execute db "SELECT name FROM foo")))
      (should resultset)
      (should (equal (sqlite3-resultset-fields resultset) '("name")))
      (dotimes (_ 3)
        (let ((row (sqlite3-resultset-next resultset)))
          (should (member (car row) '("Tom" "Bob" "Chris")))))
      (sqlite3-resultset-next resultset) ;; last call
      (should (sqlite3-resultset-eof resultset)))))

;;; test-sqlite3.el ends here
