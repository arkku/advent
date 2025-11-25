#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

#define MAX_STONES 64
#define CACHE_SIZE 131072
#define HASH_INITIAL_NUM_BUCKETS ((unsigned) CACHE_SIZE * 2U)
#define HASH_INITIAL_NUM_BUCKETS_LOG2 18
//#define DO_CLEANUP

#include <uthash.h>

typedef struct {
    uint64_t key;
    int64_t result;
    UT_hash_handle hh;
} cache_entry;

static cache_entry *cache_entries = NULL;
static cache_entry *cache = NULL;
static int_fast32_t cache_count = 0;

static cache_entry *cache_alloc(void) {
    if (cache_count < CACHE_SIZE) {
        return &cache_entries[cache_count++];
    } else {
        return NULL;
    }
}

static int64_t cache_lookup(const uint64_t key) {
    cache_entry *entry;
    HASH_FIND(hh, cache, &key, sizeof(key), entry);
    if (entry) {
        return entry->result;
    }
    return -1;
}

static void cache_add(const uint64_t key, const int64_t result) {
    cache_entry * const entry = cache_alloc();
    if (entry == NULL) {
        return;
    }
    entry->key = key;
    entry->result = result;
    HASH_ADD(hh, cache, key, sizeof(key), entry);
}

#ifdef DO_CLEANUP
static void cache_free(void) {
    cache_entry *entry;
    cache_entry *tmp;
    HASH_ITER(hh, cache, entry, tmp) {
        HASH_DEL(cache, entry);
    }
    free(cache_entries);
}
#endif

static int64_t blink(int_fast8_t times, const int64_t stone) {
    if (times == 0) {
        return 1;
    }

    const uint64_t key = ((uint64_t) times << 56) | stone;

    const int64_t cached_result = cache_lookup(key);
    if (cached_result >= 0) {
        return cached_result;
    }

    --times;

    int64_t result;

    if (stone == 0) {
        result = blink(times, 1);
    } else {
        const int digit_count = (int) (log10((double)stone) + 1);
        if (digit_count % 2 == 0) {
            const int64_t divisor = (int64_t) pow(10.0, (double) digit_count / 2);
            result = blink(times, stone / divisor) + blink(times, stone % divisor);
        } else {
            result = blink(times, stone * 2024);
        }
    }

    cache_add(key, result);
    return result;
}

int main(void) {
    int stone_count = 0;
    int64_t stones[MAX_STONES];
    const int times[] = { 25, 75, 0 };

    {
        char input[1024];

        if (!fgets(input, sizeof(input), stdin)) {
            perror("fgets");
            return EXIT_FAILURE;
        }

        const char *token = strtok(input, " \n");
        while (token && stone_count < MAX_STONES) {
            stones[stone_count++] = atoll(token);
            token = strtok(NULL, " \n");
        }
    }

    if (!(cache_entries = malloc(sizeof(*cache_entries) * (CACHE_SIZE + 1)))) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    for (int times_index = 0; times[times_index]; ++times_index) {
        int64_t sum = 0;
        for (int i = 0; i < stone_count; ++i) {
            sum += blink(times[times_index], stones[i]);
        }
        (void) printf("%lld\n", sum);
    }

#ifdef DO_CLEANUP
    cache_free();
#endif

    return EXIT_SUCCESS;
}
