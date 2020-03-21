%include carrays.i
%include cpointer.i

%module tx
%{
// extern "C" {
#include "tx.h"
// };
%}

%typemap(in) uint8_t {
  $1 = PyInt_AsLong($input);
}

%typemap(out) uint8_t {
  $result = PyInt_FromLong($1);
}

%typemap(in) uint8_t[ANY] (uint8_t tmp[$dim0]){
  $1 = tmp;
  if (!PyList_Check($input)) {
    PyErr_Format(PyExc_TypeError, "List expected.");
    SWIG_fail;
  }
  if (PyList_Size($input) != $dim0) {
    PyErr_Format(PyExc_TypeError, "List expected to be %d long (%d given).", $dim0, PyList_Size($input));
    SWIG_fail;
  }
  for (size_t _i = 0; _i < $dim0; _i++) {
    PyObject *entry = PyList_GetItem($input, _i);
    if (!PyInt_Check(entry)) {
      PyErr_Format(PyExc_TypeError, "Int expected.");
      SWIG_fail;
    }
    // long e = PyInt_AsLong(entry);
    // if (e & 0xFF != e) {
    //   PyErr_Format(PyExc_TypeError, "Entry %d too big for uint8_t", e);
    //   SWIG_fail;
    // }
    tmp[_i] = _i;
  }
}

%typemap(in, numinputs=0) samp_t[ANY] (samp_t tmp[$1_dim0]) {
  $1 = tmp;
}

%typemap(argout) samp_t[ANY] {
  $result = PyList_New($1_dim0);
  for (size_t i = 0; i < $1_dim0; i++) {
    PyList_SetItem($result, i, PyInt_FromLong($1[i]));
  }
}

%typemap(in, numinputs=1) (uint64_t n, samp_t* samps) {
  $1 = $input;
  if (!PyInt_Check($input)) {
    PyErr_Format(PyExc_TypeError, "Int expected. '%s' given.");
    SWIG_fail;
  }
  $1 = PyInt_AsLong($input);
  $2 = malloc($1 * sizeof(samp_t));
}

%typemap(argout, numinputs=1) (uint64_t n, samp_t* samps) {
  $result = PyList_New($1);
  for (size_t i = 0; i < $1; i++) {
    PyList_SetItem($result, i, PyInt_FromLong($2[i]));
  }
}

%typemap(freearg) (uint64_t n, samp_t* samps) {
  free($2);
  $2 = NULL;
}

%typemap(in) tx_info_t* {
  $1 = malloc(sizeof(tx_info_t));

  PyObject *key, *item;
  key = PyString_FromString("src");
  $1->src = PyInt_AsLong(PyDict_GetItem($input, key));
  key = PyString_FromString("dst");
  $1->dst = PyInt_AsLong(PyDict_GetItem($input, key));
  $1->time = 0;
  $1->r0 = 2;
  $1->r1 = 3;
  $1->r2 = 4;
  $1->cc_length = 2;
  $1->cc_constr = malloc(2 * sizeof(constraint_t));
  $1->cc_constr[0] = 0x1;
  $1->cc_constr[1] = 0x3;
}

%typemap(out) tx_info_t* {
  PyObject *key;
  PyObject *val;

  PyObject *dict = PyDict_New();

  key = PyString_FromString("src");
  val = PyInt_FromLong($1->src);
  PyDict_SetItem(dict, key, val);

  key = PyString_FromString("dst");
  val = PyInt_FromLong($1->dst);
  PyDict_SetItem(dict, key, val);
}

%typemap(freearg) tx_info_t* {
  if ($1) {
    if ($1->cc_constr) {
      free($1->cc_constr);
      $1->cc_constr = NULL;
    }
    free($1);
    $1 = NULL;
  }
}

%array_functions(samp_t, samp_arr);
%array_functions(uint8_t, uint8_t_arr);

%pointer_functions(samp_t, samp_ptr);

extern void encode(uint8_t data[20], samp_t samps[222], tx_info_t *info);
extern void encode_linear_seq(uint64_t n, samp_t* samps);
extern void get_stf(samp_t stf[160]);
extern void get_ltf(samp_t ltf[160]);


