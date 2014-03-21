#include "tox.h"
#include "Messenger.h"
#include "util.h"
int DESCountCloseNodes(Tox *tox) {
    Messenger *m = (Messenger *)tox;
    uint32_t i, ret = 0;
    unix_time_update();

    for (i = 0; i < LCLIENT_LIST; ++i) {
        Client_data *client = &m->dht->close_clientlist[i];

        if (!is_timeout(client->assoc4.timestamp, BAD_NODE_TIMEOUT) ||
            !is_timeout(client->assoc6.timestamp, BAD_NODE_TIMEOUT))
            ++ret;
    }

    return ret;
}
