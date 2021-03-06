@** The Lines. When more than one line is required, you need {\it lines}. 
|ll_lines| is the next abstraction up from |ll_line|. 

@<Top@>+= @<Lines@>

@* The |ll_lines| Declaration.

@ The |ll_line_entry| data struct wraps |ll_line| into a linked list entry.

@<Lines@>+=
typedef struct ll_line_entry {
    ll_line *ln ; /* main ll\_line entry */
    ll_flt val; /* store output step value */
    struct ll_line_entry *next; /* next ll\_line\_entry value */
} ll_line_entry;

@ The |ll_lines| data struct is linked list of |ll_line_entry|. 

@<Lines@>+=
struct ll_lines {
    ll_line_entry *root;
    ll_line_entry *last;
    unsigned int size;
    int sr; /* samplerate */
    ll_cb_malloc malloc;
    ll_cb_free free;
    void *ud;
    ll_line *ln;
    ll_point *pt;
    ll_flt tscale;
};

@* Lines Initialization.

@ |ll_lines_size| returns the size of the ll\_lines data struct.

@<Lines@>+=

size_t ll_lines_size()
{
    return sizeof(ll_lines);
}

@ |ll_lines_init| initializes all the data of an allocated |ll_lines| struct.

@<Lines@>+=
void ll_lines_init(ll_lines *l, int sr)
{
    l->root = NULL;
    l->last = NULL;
    l->size = 0;
    l->malloc = ll_malloc;
    l->free = ll_free;
    l->sr = sr;
    l->tscale = 1.0;
}

@* Lines Memory Handling.
@ Alternative memory allocation functions can be set for |ll_lines| via
|ll_lines_mem_callback|.

@<Lines@>+=
void ll_lines_mem_callback(ll_lines *l, void *ud, ll_cb_malloc m, ll_cb_free f)
{
    l->malloc = m;
    l->free = f;
    l->ud = ud;
}

@ The function |ll_lines_free| frees all memory previously allocated using
the internal free callback. 
@<Lines@>+=
void ll_lines_free(ll_lines *l)
{
    unsigned int i;
    ll_line_entry *entry;
    ll_line_entry *next;

    entry = l->root;

    for(i = 0; i < l->size; i++) {
        next = entry->next;
        ll_line_free(entry->ln);
        l->free(l->ud, entry->ln);
        l->free(l->ud, entry);
        entry = next;
    }
}

@* Appending a Line to Lines.
@ This creates and appends a new |ll_line| to the |ll_lines| linked list.
The address of this new |ll_line| is saved to the variable |pline|. The output
memory address of the |ll_line| is saved to the variable |val|. 

@<Lines@>+=
void ll_lines_append(ll_lines *l, ll_line **pline, ll_flt **val)
{
    ll_line_entry *entry;
   
    entry = l->malloc(l->ud, sizeof(ll_line_entry));
    entry->val = 0.f;
    entry->ln = l->malloc(l->ud, ll_line_size());
    ll_line_init(entry->ln, l->sr);
    ll_line_timescale(entry->ln, l->tscale);
  
    if(pline != NULL) *pline = entry->ln;
    if(val != NULL) *val = &entry->val;

    if(l->size == 0) {
        l->root = entry; 
    } else {
        l->last->next = entry;
    }

    l->size++;
    l->last = entry;
    l->ln = entry->ln;
}

@ The current line being created can be returned using a wrapper function called
|ll_lines_get_current|. This function is needed in order to get line data
bound to data in Sporth. 

@<Lines@>+=
ll_line * ll_lines_current_line(ll_lines *l)
{
    return l->ln;
}

@* Lines Step Function.
@ The step function for |ll_lines| will walk through the linked list and call
the step function for each |ll_line| inside each |ll_line_entry|. 

@<Lines@>+=
void ll_lines_step(ll_lines *l)
{
    unsigned int i;
    ll_line_entry *entry;

    entry = l->root;

    for(i = 0; i < l->size; i++) {
        entry->val = ll_line_step(entry->ln);
        entry = entry->next;
    }
}

@* Wrappers for adding points. The Line API provides a set of high-level
functions for populating lines with points. These use functions abstract away
some of the C structs needed, making it easier to export to higher-level
languages like Lua. 
@<Lines@>+=
void ll_add_linpoint(ll_lines *l, ll_flt val, ll_flt dur)
{
    ll_point *pt;
    pt = ll_line_append(l->ln, val, dur);
    ll_linpoint(pt);
}

void ll_add_exppoint(ll_lines *l, ll_flt val, ll_flt dur, ll_flt curve)
{
    ll_point *pt;
    pt = ll_line_append(l->ln, val, dur);
    ll_exppoint(pt, curve);
}

void ll_add_bezier(ll_lines *l, ll_flt val, ll_flt dur, ll_flt cx, ll_flt cy)
{
    ll_point *pt;
    pt = ll_line_append(l->ln, val, dur);
    ll_bezier(pt, cx, cy);
}

void ll_add_step(ll_lines *l, ll_flt val, ll_flt dur)
{
    ll_line_append(l->ln, val, dur);
}

void ll_add_tick(ll_lines *l, ll_flt dur)
{
    ll_point *pt;
    pt = ll_line_append(l->ln, 0.0, dur);
    ll_tick(pt);
}

void ll_end(ll_lines *l)
{
    ll_line_done(l->ln);
}

void ll_timescale(ll_lines *l, ll_flt scale)
{
    l->tscale = scale;
}

void ll_timescale_bpm(ll_lines *l, ll_flt bpm)
{
    l->tscale = 60.0 / bpm;
}
