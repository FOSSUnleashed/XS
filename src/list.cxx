/* list.cxx -- operations on lists */

#include "xs.hxx"
#include <algorithm>

/*
 * allocation and garbage collector support
 */

extern List *mklist(Term* term, List* next) {
	assert(term != NULL);
	List* list = gcnew(List);
	list->term = term;
	list->next = next;
	return list;
}

/*
 * basic list manipulations
 */

/* reverse -- destructively reverse a list */
extern List *reverse(List *list) {
	if (list == NULL)
		return NULL;
	List *prev = NULL, *next;
	do {
		next = list->next;
		list->next = prev;
		prev = list;
	} while ((list = next) != NULL);
	return prev;
}

/* append -- merge two lists, non-destructively */
extern List *append(const List* head, List* tail) {
	List *lp, **prevp;

	for (prevp = &lp; head; head = head->next) {
		List *np = mklist(head->term, NULL);
		*prevp = np;
		prevp = &np->next;
	}
	*prevp = tail;

	return lp;
}

/* listcopy -- make a copy of a list */
extern List *listcopy(const List *list) {
	return append(list, NULL);
}

/* length -- lenth of a list */
extern int length(List* list) {
	int len = 0;
	iterate (list) ++len;
	return len;
}

/* listify -- turn an argc/argv vector into a list */
extern List *listify(int argc, char **argv) {
	List *list = NULL;
	while (argc > 0) {
		Term *term = mkstr(argv[--argc]);
		list = mklist(term, list);
	}
	
	return list;
}

/* nth -- return nth element of a list, indexed from 1 */
extern Term *nth(List *list, int n) {
	assert(n > 0);
	iterate (list) {
		assert(list->term != NULL);
		if (--n == 0)
			return list->term;
	}
	return NULL;
}

static List* clonelistnode(List *list) {
	if (NULL == list) {
		return NULL;
	}

	return mklist(mkstr(gcdup(getstr(list->term))), NULL);
}

List *sortinsertlist(List *head, List *item) {
	if (0 < strcmp(getstr(head->term), getstr(item->term))) {
		item->next = head;
		head = item;
	} else if (NULL == head->next) {
		head->next = item;
	} else {
		head->next = sortinsertlist(head->next, item);
	}

	return head;
}

/* sortlist */
extern List* sortlist(List* list) {
	// strcmp(s1, s2) < 0
	List *result = clonelistnode(list);
	list = list->next;

	iterate(list) {
		result = sortinsertlist(result, clonelistnode(list));
	}

	return result;
}

extern Vector* vectorize(const List* list) {
       Vector* v = new (UseGC) Vector;
       iterate (list) {
               v->push_back(gcdup(getstr(list->term)));
       }

       return v;
}
