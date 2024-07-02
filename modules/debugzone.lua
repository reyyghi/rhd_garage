--- Source https://github.com/overextended/ox_lib/blob/master/imports/zones/client.lua

local glm = require 'glm'

local function nextFreePoint(points, b, len)
    for i = 1, len do
        local n = (i + b) % len

        n = n ~= 0 and n or len

        if points[n] then
            return n
        end
    end
end

local function unableToSplit(polygon)
    print('The following polygon is malformed and has failed to be split into triangles for debug')

    for k, v in pairs(polygon) do
        print(k, v)
    end
end

local function getTriangles(polygon)
    local triangles = {}

    if polygon:isConvex() then
        for i = 2, #polygon - 1 do
            triangles[#triangles + 1] = mat(polygon[1], polygon[i], polygon[i + 1])
        end

        return triangles
    end

    if not polygon:isSimple() then
        unableToSplit(polygon)

        return triangles
    end

    local points = {}
    local polygonN = #polygon

    for i = 1, polygonN do
        points[i] = polygon[i]
    end

    local a, b, c = 1, 2, 3
    local zValue = polygon[1].z
    local count = 0

    while polygonN - #triangles > 2 do
        local a2d = polygon[a].xy
        local c2d = polygon[c].xy

        if polygon:containsSegment(vec3(glm.segment2d.getPoint(a2d, c2d, 0.01), zValue), vec3(glm.segment2d.getPoint(a2d, c2d, 0.99), zValue)) then
            triangles[#triangles + 1] = mat(polygon[a], polygon[b], polygon[c])
            points[b] = false

            b = c
            c = nextFreePoint(points, b, polygonN)
        else
            a = b
            b = c
            c = nextFreePoint(points, b, polygonN)
        end

        count += 1

        if count > polygonN and #triangles == 0 then
            unableToSplit(polygon)

            return triangles
        end

        Wait(0)
    end

    return triangles
end


local DrawLine = DrawLine
local DrawPoly = DrawPoly

local function debugPoly(self)
    for i = 1, #self.triangles do
        local triangle = self.triangles[i]
        DrawPoly(triangle[1].x, triangle[1].y, triangle[1].z, triangle[2].x, triangle[2].y, triangle[2].z, triangle[3].x, triangle[3].y, triangle[3].z,
            self.debugColour.r, self.debugColour.g, self.debugColour.b, self.debugColour.a)
        DrawPoly(triangle[2].x, triangle[2].y, triangle[2].z, triangle[1].x, triangle[1].y, triangle[1].z, triangle[3].x, triangle[3].y, triangle[3].z,
            self.debugColour.r, self.debugColour.g, self.debugColour.b, self.debugColour.a)
    end
    for i = 1, #self.polygon do
        local thickness = vec(0, 0, self.thickness / 2)
        local a = self.polygon[i] + thickness
        local b = self.polygon[i] - thickness
        local c = (self.polygon[i + 1] or self.polygon[1]) + thickness
        local d = (self.polygon[i + 1] or self.polygon[1]) - thickness
        DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, self.debugColour.r, self.debugColour.g, self.debugColour.b, 225)
        DrawLine(a.x, a.y, a.z, c.x, c.y, c.z, self.debugColour.r, self.debugColour.g, self.debugColour.b, 225)
        DrawLine(b.x, b.y, b.z, d.x, d.y, d.z, self.debugColour.r, self.debugColour.g, self.debugColour.b, 225)
        DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, self.debugColour.r, self.debugColour.g, self.debugColour.b, self.debugColour.a)
        DrawPoly(c.x, c.y, c.z, b.x, b.y, b.z, a.x, a.y, a.z, self.debugColour.r, self.debugColour.g, self.debugColour.b, self.debugColour.a)
        DrawPoly(b.x, b.y, b.z, c.x, c.y, c.z, d.x, d.y, d.z, self.debugColour.r, self.debugColour.g, self.debugColour.b, self.debugColour.a)
        DrawPoly(d.x, d.y, d.z, c.x, c.y, c.z, b.x, b.y, b.z, self.debugColour.r, self.debugColour.g, self.debugColour.b, self.debugColour.a)
    end
end

return {
    start = function (polygon, thickness)
        debugPoly({
            polygon = polygon,
            thickness = thickness,
            triangles = getTriangles(polygon),
            debugColour = {
                r = 240,
                g = 229,
                b = 5,
                a = 50
            }
        })
    end
}
