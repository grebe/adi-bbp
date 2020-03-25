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
    tmp[_i] = PyInt_AsLong(entry);
    // Py_DECREF(entry);
  }
}

%typemap(in, numinputs=0) samp_t[ANY] (samp_t tmp[$1_dim0]) {
  $1 = tmp;
}

%typemap(argout) samp_t[ANY] {
  $result = PyList_New($1_dim0);
  for (size_t i = 0; i < $1_dim0; i++) {
    PyObject *o = PyInt_FromLong($1[i]);
    PyList_SetItem($result, i, o);
  }
}

%typemap(in, numinputs=1) (uint64_t n, samp_t* samps) {
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
    PyObject *o = PyInt_FromLong($2[i]);
    PyList_SetItem($result, i, o);
  }
}

%typemap(freearg) (uint64_t n, samp_t* samps) {
  free($2);
  $2 = NULL;
}

%typemap(in) tx_info_t* {

  $1 = malloc(sizeof(tx_info_t));

  // check if $input is a dict
  if (!PyDict_Check($input)) {
    PyErr_Format(PyExc_TypeError, "Dict expected");
    SWIG_fail;
  }

  PyObject *key, *item;

  // src (mandatory)
  key = PyString_FromString("src");
  item = PyDict_GetItemWithError($input, key);
  Py_DECREF(key);

  if (!item) {
    PyErr_Format(PyExc_TypeError, "Key src not found.");
    SWIG_fail;
  }
  if (!PyInt_Check(item)) {
    PyErr_Format(PyExc_TypeError, "Key src not an int.");
    SWIG_fail;
  }
  $1->src = PyInt_AsLong(item);
  // Py_DECREF(item);

  // dst (mandatory)
  key = PyString_FromString("dst");
  item = PyDict_GetItemWithError($input, key);
  Py_DECREF(key);

  if (!item) {
    PyErr_Format(PyExc_TypeError, "Key dst not found.");
    SWIG_fail;
  }
  if (!PyInt_Check(item)) {
    PyErr_Format(PyExc_TypeError, "Key dst not an int.");
    SWIG_fail;
  }
  $1->dst = PyInt_AsLong(item);
  // Py_DECREF(item);

  $1->time = 0;

  // r0 (optional)
  key = PyString_FromString("r0");
  item = PyDict_GetItem($input, key);
  Py_DECREF(key);

  if (item) {
    if (!PyInt_Check(item)) {
      PyErr_Format(PyExc_TypeError, "Key r0 not an int");
      SWIG_fail;
    }
    $1->r0 = PyInt_AsLong(item);
    // Py_DECREF(item);
  } else {
    $1->r0 = 2;
  }

  // r1 (optional)
  key = PyString_FromString("r1");
  item = PyDict_GetItem($input, key);
  Py_DECREF(key);

  if (item) {
    if (!PyInt_Check(item)) {
      PyErr_Format(PyExc_TypeError, "Key r1 not an int");
      SWIG_fail;
    }
    $1->r1 = PyInt_AsLong(item);
    // Py_DECREF(item);
  } else {
    $1->r1 = 3;
  }

  // r2 (optional)
  key = PyString_FromString("r2");
  item = PyDict_GetItem($input, key);
  Py_DECREF(key);

  if (item) {
    if (!PyInt_Check(item)) {
      PyErr_Format(PyExc_TypeError, "Key r2 not an int");
      SWIG_fail;
    }
    $1->r2 = PyInt_AsLong(item);
    // Py_DECREF(item);
  } else {
    $1->r2 = 4;
  }

  // pilots (optional)
  key = PyString_FromString("pilots");
  item = PyDict_GetItem($input, key);
  Py_DECREF(key);

  if (item) {
    if (!PyDict_Check(item)) {
      PyErr_Format(PyExc_TypeError, "Key pilot not a dict");
      SWIG_fail;
    }
    $1->num_pilots = PyDict_Size(item);
    $1->pilots = malloc($1->num_pilots * sizeof(pilot_tone));

    Py_ssize_t pos = 0;

    PyObject *pilot_idx, *pilot_value;
    uint64_t _i = 0;
    while (PyDict_Next(item, &pos, &pilot_idx, &pilot_value)) {
      if (PyInt_Check(pilot_idx)) {
        $1->pilots[_i].pos = PyInt_AsLong(pilot_idx);
      } else {
        PyErr_Format(PyExc_TypeError, "Key in dict not an int");
        SWIG_fail;
      }
      if (PyInt_Check(pilot_value)) {
        $1->pilots[_i].real = (double)PyInt_AsLong(pilot_value);
        $1->pilots[_i].imag = 0.0;
      } else if (PyFloat_Check(pilot_value)) {
        $1->pilots[_i].real = PyFloat_AsDouble(pilot_value);
        $1->pilots[_i].imag = 0.0;
      } else if (PyComplex_Check(pilot_value)) {
        $1->pilots[_i].real = PyComplex_RealAsDouble(pilot_value);
        $1->pilots[_i].imag = PyComplex_ImagAsDouble(pilot_value);
      } else {
        PyErr_Format(PyExc_TypeError, "Pilot at %d not a number", PyInt_AsLong(pilot_idx));
        SWIG_fail;
      }

      // Py_DECREF(pilot_idx);
      // Py_DECREF(pilot_value);
      _i++;
    }

    // Py_DECREF(item);
  } else {
    // fill in the default {}
    $1->num_pilots = 8;
    $1->pilots = malloc($1->num_pilots * sizeof(pilot_tone));

    $1->pilots[0].pos = 4;
    $1->pilots[1].pos = 12;
    $1->pilots[2].pos = 20;
    $1->pilots[3].pos = 28;
    $1->pilots[4].pos = 36;
    $1->pilots[5].pos = 44;
    $1->pilots[6].pos = 52;
    $1->pilots[7].pos = 60;

    for (int i = 0; i < 8; i++) {
      $1->pilots[i].real = $1->pilots[i].imag = 1.0;
    }
  }

  // make sure pilots are sorted by idx
  qsort($1->pilots, $1->num_pilots, sizeof(pilot_tone), pilot_compare);

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
  Py_DECREF(key);

  key = PyString_FromString("dst");
  val = PyInt_FromLong($1->dst);
  PyDict_SetItem(dict, key, val);
  Py_DECREF(key);
}

%typemap(freearg) tx_info_t* {
  if ($1) {
    if ($1->pilots) {
      free($1->pilots);
      $1->pilots = NULL;
      $1->num_pilots = 0;
    }
    if ($1->cc_constr) {
      free($1->cc_constr);
      $1->cc_constr = NULL;
      $1->cc_length = 0;
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


