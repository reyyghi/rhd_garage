--- Source https://github.com/overextended/ox_lib/blob/master/imports/zones/client.lua

local function getTriangles(polygon)
    local triangles = {}

    if polygon:isConvex() then
        for i = 2, #polygon - 1 do
            triangles[#triangles + 1] = mat(polygon[1], polygon[i], polygon[i + 1])
        end

        return triangles
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
    start = function (polygon, thickness, color)
        debugPoly({
            polygon = polygon,
            thickness = thickness,
            triangles = getTriangles(polygon),
            debugColour = color
        })
    end
}
