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

int DESCopyNetAddress(Tox *tox, int32_t peernum, char **ip_out, uint16_t *port_out) {
    //if (!tox_get_friend_connection_status(tox, peernum))
    //    return 0;
    Messenger *priv = (Messenger *)tox;
    /* CCID for net_crypto. */
    int ccid = priv -> friendlist[peernum].crypt_connection_id;
    /* LUID for lossless UDP connection. */
    uint16_t luid = priv -> net_crypto -> crypto_connections[ccid].number;
    tox_array isconns = priv -> net_crypto -> lossless_udp -> connections;
    IP_Port identity = (&tox_array_get(&isconns, luid, Connection))->ip_port;
    if (identity.ip.family == AF_INET) {
        char *s = malloc(INET_ADDRSTRLEN);
        inet_ntop(AF_INET, identity.ip.ip4.uint8, s, INET_ADDRSTRLEN);
        if (ip_out)
            *ip_out = s;
        else
            free(s);
    } else {
        char *s = malloc(INET6_ADDRSTRLEN);
        inet_ntop(AF_INET6, identity.ip.ip6.uint8, s, INET6_ADDRSTRLEN);
        if (ip_out)
            *ip_out = s;
        else
            free(s);
    }
    if (port_out)
        *port_out = ntohs(identity.port);
    return 1;
}
