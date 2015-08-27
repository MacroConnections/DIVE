from data.access import is_numeric
from itertools import combinations
from data.db import MongoInstance as MI
from viz_stats import *
from scipy import stats as sc_stats

from pprint import pprint
from time import time

# Wrapper function
def get_viz_specs(pID):
    datasets = MI.getData(None, pID)
    properties = MI.getProperty(None, pID)
    ontologies = MI.getOntology(None, pID)

    existing_specs = MI.getSpecs(pID, {})
    enumerated_viz_specs = enumerate_viz_specs(datasets, properties, ontologies)
    filtered_viz_specs = filter_viz_specs(enumerated_viz_specs)
    scored_viz_specs = score_viz_specs(filtered_viz_specs)
    return scored_viz_specs

specific_to_general_type = {
    'float': 'q',
    'integer': 'q',
    'string': 'c',
    'continent': 'c',
    'countryName': 'c',
    'datetime': 'q'
}

# TODO How to document defaults?
aggregation_functions = {
    'sum': np.sum,
    'min': np.min,
    'max': np.max,
    'mean': np.mean,
    'count': np.size
}

elementwise_functions = {
    'add': '+',
    'subtract': '-',
    'multiply': '*',
    'divide': '/'
}

def A(label):
    specs = []

    # { Index: value }
    index_spec = {
        'structure': 'ind:val',
        'args': {
            'field_a': label
        },
        'meta': {
            'desc': 'Plot %s against its index' % label
        }
    }
    specs.append(index_spec)

    # TODO Make this depend on non-unique values
    # { Value: count }
    count_spec = {
        'structure': 'val:count',
        'args': {
            'field_a': label
        },
        'meta': {
            'desc': 'Plot values of %s against count of occurrences' % label
        }
    }
    specs.append(count_spec)

    # TODO Implement binning algorithm
    # { Bins: Aggregate(binned values) }
    for agg_fn in aggregation_functions.keys():
        bin_spec = {
            'structure': 'bin:agg',
            'args': {
                'agg_fn': agg_fn,
                'agg_field_a': label,
                'binning_spec': 0,
                'binning_field': label
            },
            'meta': {
                'desc': 'Bin %s, then aggregate binned values by %s' % (label, agg_fn)
            }
        }
        specs.append(bin_spec)
    return specs

def B(labels):
    specs = []
    # Function on pairs of columns
    for (field_a, field_b) in combinations(labels, 2):
        for ew_fn, ew_op in elementwise_functions.iteritems():
            derived_column_desc = "%s %s %s" % (field_a, ew_op, field_b)
            A_specs = A(derived_column_desc)
            specs.extend(A_specs)
    return specs

def C(label):
    specs = []

    # TODO Only create if values are non-unique
    spec = {
        'structure': 'val:count',
        'args': {
            'field_a': label
        },
        'meta': {
            'desc': 'Unique values of %s mapped to number of occurrences' % (label)
        }
    }
    return specs

def D(c_label, q_label):
    specs = []
    c_unique = false

    # One case of A
    a_spec = A(c_label)
    specs.append(a_spec)

    # One case of C
    c_spec = C(q_label)
    specs.append(q_label)

    # If c_label is unique
    if c_unique:
        spec = {
            'structure': 'val:val',
            'args': {
                'field_a': c_label,
                'field_b': q_label
            },
            'meta': {
                'desc': 'Plotting raw values of %s against corresponding values of %s' % (c_label, q_label)
            }
        }
        spec.append(spec)
    else:
        for agg_fn in aggregation_functions.keys():
            spec = {
                'structure': 'val:agg',
                'args': {
                    'agg_fn': c_label,
                    'grouped_field': c_label,
                    'agg_field': q_label,
                },
                'meta': {
                    'desc': 'Plotting raw values of %s against corresponding values of %s, aggregated by %s' % (c_label, q_label, agg_fn)
                }
            }
            specs.append(spec)
    return specs


# TODO Move the case classifying into dataset ingestion (doesn't need to be here!)
# 1) Enumerated viz specs given data, properties, and ontologies
def enumerate_viz_specs(datasets, properties, ontologies):
    dIDs = [ d['dID'] for d in datasets ]
    specs_by_dID = dict([(dID, []) for dID in dIDs])

    types_by_dID = {}
    properties_by_dID = {}
    labels_by_dID = {}
    for p in properties:
        dID = p['dID']
        if dID in properties_by_dID and dID in types_by_dID:
            # TODO Necessary to preserve the order of fields?
            types_by_dID[dID].append(p['type'])
            labels_by_dID[dID].append(p['label'])
            properties_by_dID[dID].append(p)
        else:
            types_by_dID[dID] = [ p['type'] ]
            labels_by_dID[dID] = [ p['label'] ]
            properties_by_dID[dID] = [ p ]

    # Iterate through datasets (no cross-dataset visualizations for now)
    for dID in properties_by_dID.keys():
        specs = []
        specific_types = types_by_dID[dID]
        labels = labels_by_dID[dID]
        types = [ specific_to_general_type[t] for t in specific_types ]
        properties = properties_by_dID[dID]

        q_count = types.count('q')
        c_count = types.count('c')

        print "\tN_q:", q_count
        print "\tN_c:", c_count

        # Cases A - B
        # Q > 0, C = 0
        # TODO Formalization for specs
        if q_count and not c_count:
            # Case A) Q = 1, C = 0
            if q_count == 1:
                print "Case A"
                label = labels[0]
                A_specs = A(label)
                specs.extend(A_specs)
            elif q_count >= 1:
                print "Case B"
                for label in labels:
                    A_specs = A(label)
                    specs.extend(A_specs)
                B_specs = B(labels)
                specs.extend(B_specs)

        # Cases C - E
        # C = 1
        if c_count == 1:
            # Case C) C = 1, Q = 0
            if q_count == 0:
                print "Case C"
                continue
            # Case D) C = 1, Q = 1
            elif q_count == 1:
                print "Case D"
                continue
            # Case E) C = 1, Q >= 1
            elif q_count > 1:
                print "Case E"
                continue

        # Cases F - H
        # C >= 1
        if c_count >= 1:
            # Case F) C >= 1, Q = 0
            if q_count == 0:
                print "Case F"
                continue
            # Case G) C >= 1, Q = 1
            elif q_count == 1:
                print "Case G"
                continue
            # Case H) C >= 1, Q > 1
            elif q_count > 1:
                print "Case H"
                continue
        specs_by_dID[dID] = specs

    print "Specs:", len(specs_by_dID)
    pprint(specs_by_dID)
    return specs_by_dID
# 2) Filtering enumerated viz specs based on interpretability and renderability
def filter_viz_specs(enumerated_viz_specs):
    filtered_viz_specs = []
    return filtered_viz_specs

# 3) Scoring viz specs based on effectiveness, expressiveness, and statistical properties
def score_viz_specs(filtered_viz_specs):
    scored_viz_specs = []
    return scored_viz_specs
