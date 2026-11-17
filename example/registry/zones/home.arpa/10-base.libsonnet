{
  ns1: { a: '192.168.1.2' },
  router: { a: '192.168.1.1' },
  nas: { a: '192.168.1.10' },
  www: { cname: 'nas' },
  app: { cname: 'nas' },

  // XMPP and Matrix. RFC 2782 wants the target of an SRV record to have an address, not a CNAME.
  chat: { a: '192.168.1.20' },
  '_xmpp-client._tcp': { srv: '5 0 5222 chat' },
  '_xmpp-server._tcp': { srv: '5 0 5269 chat' },
  '_matrix-fed._tcp': { srv: '10 0 8448 chat' },
}
